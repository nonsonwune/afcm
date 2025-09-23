import { serve } from "../_shared/deps.ts";
import { createAdminClient } from "../_shared/supabase.ts";

type CreateOrderRequest = {
  badgeSku?: string;
  name?: string;
  email?: string;
  phone?: string;
  role?: string;
};

type PaystackInvoiceResponse = {
  status: boolean;
  message: string;
  data?: {
    request_code?: string;
    code?: string;
    hosted_link?: string;
    reference?: string;
  };
};

const jsonResponse = (status: number, payload: Record<string, unknown>): Response =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY");

if (!paystackSecret) {
  console.warn("PAYSTACK_SECRET_KEY is not configured; create-order function will return 503");
}

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  let body: CreateOrderRequest;
  try {
    body = await req.json();
  } catch (error) {
    console.error("Failed to parse JSON body", error);
    return jsonResponse(400, { error: "Invalid JSON payload" });
  }

  const { badgeSku, email, name, phone, role } = body;

  if (!badgeSku || !email || !name) {
    return jsonResponse(400, { error: "badgeSku, email, and name are required" });
  }

  if (!paystackSecret) {
    return jsonResponse(503, { error: "Payment processor unavailable" });
  }

  const supabaseAccessToken = req.headers.get("Authorization")?.replace(/Bearer\s+/i, "");
  const supabase = createAdminClient({ accessToken: supabaseAccessToken });

  const { data: authUser, error: authError } = supabaseAccessToken
    ? await supabase.auth.getUser(supabaseAccessToken)
    : { data: null, error: null };

  if (authError) {
    console.error("Failed to fetch auth user", authError);
    return jsonResponse(401, { error: "Invalid session token" });
  }

  const userId = authUser?.user?.id;

  if (!userId) {
    return jsonResponse(401, { error: "User session required" });
  }

  const { data: product, error: productError } = await supabase
    .from("pass_products")
    .select("sku, name, description, price_kobo")
    .eq("sku", badgeSku)
    .eq("is_active", true)
    .maybeSingle();

  if (productError) {
    console.error("Failed to load pass product", productError);
    return jsonResponse(500, { error: "Unable to load pass details" });
  }

  if (!product) {
    return jsonResponse(404, { error: "Pass not found or inactive" });
  }

  const primaryRole = role && ["investor", "buyer", "seller", "attendee"].includes(role)
    ? role
    : "attendee";

  const profilePayload = {
    id: userId,
    email,
    name,
    phone: phone ?? null,
    role: primaryRole,
    updated_at: new Date().toISOString(),
  };

  const { error: upsertError } = await supabase
    .from("users")
    .upsert(profilePayload, { onConflict: "id" });

  if (upsertError) {
    console.error("Failed to upsert profile", upsertError);
    return jsonResponse(500, { error: "Unable to sync profile" });
  }

  const { data: orderRows, error: orderError } = await supabase.rpc(
    "create_attendee_order",
    { p_user_id: userId, p_badge_sku: badgeSku, p_currency: "NGN" },
  );

  if (orderError) {
    console.error("Failed to create attendee/order", orderError);
    return jsonResponse(500, { error: "Unable to start order" });
  }

  const orderRow = Array.isArray(orderRows) ? orderRows[0] : orderRows;

  if (!orderRow?.order_id) {
    return jsonResponse(500, { error: "Order was not created" });
  }

  const { order_id: orderId, attendee_id: attendeeId, amount_kobo: amountKobo } = orderRow as {
    order_id: string;
    attendee_id: string;
    amount_kobo: number;
  };

  const paystackPayload = {
    customer: email,
    amount: amountKobo,
    currency: "NGN",
    description: `${product.name} – AFCM Event Pass`,
    metadata: {
      attendee_id: attendeeId,
      order_id: orderId,
      badge_sku: product.sku,
      name,
      phone,
      role: primaryRole,
    },
  };

  const invoiceResponse = await fetch("https://api.paystack.co/paymentrequest", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${paystackSecret}`,
    },
    body: JSON.stringify(paystackPayload),
  });

  const invoiceJson = (await invoiceResponse.json()) as PaystackInvoiceResponse;

  if (!invoiceResponse.ok || !invoiceJson.status || !invoiceJson.data) {
    console.error("Paystack invoice creation failed", invoiceJson);
    return jsonResponse(502, { error: "Unable to create payment invoice", details: invoiceJson.message });
  }

  const requestCode = invoiceJson.data.request_code ?? invoiceJson.data.code ?? null;
  const hostedLink = invoiceJson.data.hosted_link ?? null;
  const reference = invoiceJson.data.reference ?? null;

  const { error: updateOrderError } = await supabase
    .from("orders")
    .update({
      paystack_invoice_code: requestCode,
      paystack_reference: reference,
    })
    .eq("id", orderId);

  if (updateOrderError) {
    console.error("Failed to persist invoice codes", updateOrderError);
    return jsonResponse(500, { error: "Order created but invoice could not be saved" });
  }

  await supabase.from("notifications").insert({
    user_id: userId,
    kind: "paystack_invoice",
    channel: "email",
    payload: {
      order_id: orderId,
      attendee_id: attendeeId,
      hosted_link: hostedLink,
      request_code: requestCode,
    },
    status: hostedLink ? "queued" : "queued",
  });

  return jsonResponse(201, {
    orderId,
    attendeeId,
    message: "Invoice sent",
    amountKobo,
    hostedLink,
    requestCode,
  });
});
