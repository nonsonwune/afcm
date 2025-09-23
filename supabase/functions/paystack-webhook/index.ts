import { serve } from "../_shared/deps.ts";
import { createAdminClient } from "../_shared/supabase.ts";

const paystackSecret = Deno.env.get("PAYSTACK_SECRET_KEY");
const qrSecret = Deno.env.get("QR_SECRET");

if (!paystackSecret) {
  console.warn("PAYSTACK_SECRET_KEY is not set; webhook will reject requests");
}

if (!qrSecret) {
  console.warn("QR_SECRET is not set; tickets cannot be generated");
}

const encoder = new TextEncoder();

const toBase64Url = (bytes: Uint8Array): string => {
  const binary = String.fromCharCode(...bytes);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
};

const jsonResponse = (status: number, payload: Record<string, unknown>): Response =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const toHex = (bytes: ArrayBuffer): string =>
  Array.from(new Uint8Array(bytes))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

const verifySignature = async (secret: string, payload: string, signature: string): Promise<boolean> => {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );

  const digest = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  const expected = toHex(digest);
  return signature.toLowerCase() === expected.toLowerCase();
};

const parseDateRange = (rangeLiteral: string): { start: string; end: string } => {
  const trimmed = rangeLiteral.trim();
  const inner = trimmed.replace(/^[\[(]/, "").replace(/[\])]$/, "");
  const [start, end] = inner.split(",");
  if (!start || !end) {
    throw new Error(`Invalid daterange literal: ${rangeLiteral}`);
  }
  return { start: start.trim(), end: end.trim() };
};

const buildQrPayload = async (ticketId: string, attendeeId: string, badgeSku: string, validUntilDate: string): Promise<string> => {
  if (!qrSecret) {
    throw new Error("QR_SECRET not configured");
  }

  const expiresAt = Math.floor(new Date(`${validUntilDate}T23:59:59+01:00`).getTime() / 1000);
  const payload = {
    t: "TKT",
    tid: ticketId,
    aid: attendeeId,
    sku: badgeSku,
    exp: expiresAt,
  };

  const payloadBytes = encoder.encode(JSON.stringify(payload));
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(qrSecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const digest = await crypto.subtle.sign("HMAC", key, payloadBytes);
  const signature = toBase64Url(new Uint8Array(digest));
  const body = toBase64Url(payloadBytes);
  return `AFCM1.${signature}.${body}`;
};

serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  if (!paystackSecret) {
    return jsonResponse(503, { error: "Webhook secret unavailable" });
  }

  const signature = req.headers.get("x-paystack-signature");
  if (!signature) {
    return jsonResponse(400, { error: "Missing signature" });
  }

  const rawBody = await req.text();

  const isValidSignature = await verifySignature(paystackSecret, rawBody, signature);
  if (!isValidSignature) {
    return jsonResponse(401, { error: "Invalid signature" });
  }

  let event: any;
  try {
    event = JSON.parse(rawBody);
  } catch (error) {
    console.error("Unable to parse webhook payload", error);
    return jsonResponse(400, { error: "Invalid JSON" });
  }

  const requestCode: string | undefined = event?.data?.request_code ?? event?.data?.code ?? event?.data?.paymentrequest_code;

  if (!requestCode) {
    return jsonResponse(400, { error: "Missing request code" });
  }

  const supabase = createAdminClient();

  const { data: order, error: orderError } = await supabase
    .from("orders")
    .select("id, attendee_id, badge_sku, status, paystack_invoice_code")
    .or(`paystack_invoice_code.eq.${requestCode},paystack_reference.eq.${requestCode}`)
    .maybeSingle();

  if (orderError) {
    console.error("Failed to load order for webhook", orderError);
    return jsonResponse(500, { error: "Order lookup failed" });
  }

  if (!order) {
    return jsonResponse(404, { error: "Order not found" });
  }

  if (order.status === "paid") {
    return jsonResponse(200, { message: "Order already processed" });
  }

  const verifyResponse = await fetch(`https://api.paystack.co/paymentrequest/verify/${requestCode}`, {
    headers: {
      Authorization: `Bearer ${paystackSecret}`,
    },
  });

  const verifyJson = await verifyResponse.json();

  if (!verifyResponse.ok || !verifyJson?.status) {
    console.error("Paystack verification failed", verifyJson);
    return jsonResponse(502, { error: "Unable to verify payment" });
  }

  if (verifyJson.data?.status !== "paid") {
    return jsonResponse(202, { message: "Invoice not paid yet" });
  }

  const reference: string | undefined = verifyJson.data?.request_code ?? verifyJson.data?.code ?? verifyJson.data?.reference;

  const nowIso = new Date().toISOString();

  const { error: updateOrderError } = await supabase
    .from("orders")
    .update({ status: "paid", processed_at: nowIso, paystack_reference: reference ?? order.paystack_invoice_code })
    .eq("id", order.id);

  if (updateOrderError) {
    console.error("Failed to update order status", updateOrderError);
    return jsonResponse(500, { error: "Could not update order" });
  }

  const { error: attendeeUpdateError } = await supabase
    .from("attendees")
    .update({ status: "PAID" })
    .eq("id", order.attendee_id);

  if (attendeeUpdateError) {
    console.error("Failed to update attendee status", attendeeUpdateError);
    return jsonResponse(500, { error: "Could not update attendee" });
  }

  const { data: existingTicket } = await supabase
    .from("tickets")
    .select("id")
    .eq("attendee_id", order.attendee_id)
    .maybeSingle();

  if (existingTicket) {
    return jsonResponse(200, { message: "Order processed" });
  }

  const { data: validRangeLiteral, error: rangeError } = await supabase.rpc("pass_valid_dates", { p_sku: order.badge_sku });

  if (rangeError || !validRangeLiteral) {
    console.error("Failed to compute valid dates", rangeError);
    return jsonResponse(500, { error: "Unable to compute ticket validity" });
  }

  const { start: validFrom, end: validTo } = parseDateRange(validRangeLiteral as string);

  const ticketId = crypto.randomUUID();
  const qrPayload = await buildQrPayload(ticketId, order.attendee_id, order.badge_sku, validTo);

  const { error: ticketError } = await supabase.from("tickets").insert({
    id: ticketId,
    attendee_id: order.attendee_id,
    pass_sku: order.badge_sku,
    valid_from: validFrom,
    valid_to: validTo,
    valid_dates: `[${validFrom},${validTo}]`,
    qr_payload: qrPayload,
  });

  if (ticketError) {
    console.error("Failed to insert ticket", ticketError);
    return jsonResponse(500, { error: "Ticket generation failed" });
  }

  await supabase.from("notifications").insert({
    user_id: null,
    kind: "ticket_issued",
    channel: "email",
    payload: {
      attendee_id: order.attendee_id,
      order_id: order.id,
      ticket_id: ticketId,
    },
    status: "queued",
  });

  return jsonResponse(200, { message: "Order marked as paid" });
});
