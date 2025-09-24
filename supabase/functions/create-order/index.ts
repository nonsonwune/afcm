import { loadConfig } from '../_shared/config.ts';
import { dayjs, dayjsTimezonePlugin, dayjsUtcPlugin } from '../_shared/deps.ts';
import { createPaymentRequest, sendPaymentRequest } from '../_shared/paystack.ts';
import { getSupabaseClient } from '../_shared/supabase.ts';

dayjs.extend(dayjsUtcPlugin);
dayjs.extend(dayjsTimezonePlugin);

interface CreateOrderInput {
  pass_sku: string;
  full_name: string;
  email: string;
  phone?: string;
  company?: string;
  attendee_role: string;
  resend_invoice?: boolean;
}

interface JsonResponse {
  status: 'ok' | 'error';
  message: string;
  data?: Record<string, unknown>;
}

const config = loadConfig();
const supabase = getSupabaseClient();

function jsonResponse(body: JsonResponse, init?: ResponseInit) {
  return new Response(JSON.stringify(body), {
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    ...init,
  });
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'content-type, authorization',
      },
    });
  }

  if (req.method !== 'POST') {
    return jsonResponse(
      { status: 'error', message: 'Method not allowed' },
      { status: 405 },
    );
  }

  try {
    const payload = (await req.json()) as Partial<CreateOrderInput>;
    const validationError = validatePayload(payload);
    if (validationError) {
      return jsonResponse({ status: 'error', message: validationError }, { status: 400 });
    }

    const input = payload as CreateOrderInput;
    const { pass_sku: passSku, email } = input;

    const { data: passProduct, error: passError } = await supabase
      .from('pass_products')
      .select('*')
      .eq('sku', passSku)
      .eq('is_active', true)
      .maybeSingle();

    if (passError) {
      console.error('Fetch pass error', passError);
      throw new Error('Unable to fetch pass details.');
    }
    if (!passProduct) {
      return jsonResponse({ status: 'error', message: 'Pass unavailable.' }, { status: 404 });
    }

    const existingPending = await findPendingOrderByEmail(email);

    if (existingPending && !input.resend_invoice) {
      return jsonResponse({
        status: 'ok',
        message: 'Existing pending order found.',
        data: existingPending,
      });
    }

    if (existingPending && input.resend_invoice) {
      await sendPaymentRequest(existingPending.paystack_request_code as string, config.paystack);
      return jsonResponse({
        status: 'ok',
        message: 'Invoice resent successfully.',
        data: existingPending,
      });
    }

    const attendeeId = await upsertPendingAttendee({
      email,
      passProductId: passProduct.id,
      attendeeRole: input.attendee_role,
      fullName: input.full_name,
      phone: input.phone,
      company: input.company,
    });
    const orderId = crypto.randomUUID();

    const expiresAt = dayjs().add(48, 'hour').toISOString();

    const description = `${passProduct.name} – AFCM 2025`;

    const { error: orderInsertError } = await supabase.from('orders').insert({
      id: orderId,
      attendee_id: attendeeId,
      pass_product_id: passProduct.id,
      status: 'pending',
      amount_kobo: passProduct.amount_kobo,
      currency: passProduct.currency,
      expires_at: expiresAt,
      metadata: {
        attendee_role: input.attendee_role,
        attendee_email: email,
        attendee_name: input.full_name,
      },
    });

    if (orderInsertError) {
      console.error('order insert error', orderInsertError);
      throw new Error('Unable to create order.');
    }

    const paymentRequest = await createPaymentRequest(
      {
        customer: email,
        amount: passProduct.amount_kobo,
        currency: passProduct.currency,
        description,
        due_date: expiresAt,
        metadata: {
          order_id: orderId,
          attendee_id: attendeeId,
          pass_sku: passSku,
          attendee_role: input.attendee_role,
        },
        line_items: [
          {
            name: description,
            amount: passProduct.amount_kobo,
            quantity: 1,
          },
        ],
      },
      config.paystack,
    );

    const paystackData = paymentRequest.data;

    const { error: orderUpdateError } = await supabase
      .from('orders')
      .update({
        paystack_request_code: paystackData.request_code,
        paystack_invoice_url: paystackData.hosted_link,
        paystack_pdf_url: paystackData.pdf_url,
        paystack_meta: paystackData,
      })
      .eq('id', orderId);

    if (orderUpdateError) {
      console.error('order update error', orderUpdateError);
      throw new Error('Unable to persist payment data.');
    }

    return jsonResponse({
      status: 'ok',
      message: 'Invoice created successfully.',
      data: {
        order_id: orderId,
        attendee_id: attendeeId,
        payment_request_code: paystackData.request_code,
        hosted_link: paystackData.hosted_link,
        pdf_url: paystackData.pdf_url,
      },
    });
  } catch (error) {
    console.error('create-order error', error);
    return jsonResponse(
      {
        status: 'error',
        message: error instanceof Error ? error.message : 'Unexpected error occurred.',
      },
      { status: 500 },
    );
  }
});

function validatePayload(payload: Partial<CreateOrderInput> | null): string | null {
  if (!payload) return 'Invalid payload.';
  const requiredFields: Array<keyof CreateOrderInput> = [
    'pass_sku',
    'full_name',
    'email',
    'attendee_role',
  ];
  for (const field of requiredFields) {
    if (!payload[field] || (payload[field] as string).trim().length === 0) {
      return `Missing ${field}.`;
    }
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(payload.email!)) {
    return 'Invalid email address.';
  }

  if (!['investor', 'buyer', 'seller', 'attendee'].includes(payload.attendee_role!)) {
    return 'Invalid attendee role.';
  }

  return null;
}

async function findPendingOrderByEmail(email: string) {
  const { data, error } = await supabase
    .from('attendees')
    .select(
      `
        id,
        full_name,
        status,
        orders:orders!inner(
          id,
          status,
          paystack_request_code,
          paystack_invoice_url,
          created_at
        )
      `,
    )
    .eq('email', email)
    .eq('orders.status', 'pending')
    .order('created_at', { referencedTable: 'orders', ascending: false })
    .maybeSingle();

  if (error && error.code !== 'PGRST116') {
    console.error('findPendingOrder error', error);
    throw new Error('Unable to look up existing orders.');
  }

  if (!data) return null;
  const order = data.orders?.[0];
  if (!order) return null;

  return {
    attendee_id: data.id,
    order_id: order.id,
    paystack_request_code: order.paystack_request_code,
    hosted_link: order.paystack_invoice_url,
  };
}

async function upsertPendingAttendee({
  email,
  passProductId,
  attendeeRole,
  fullName,
  phone,
  company,
}: {
  email: string;
  passProductId: string;
  attendeeRole: string;
  fullName: string;
  phone?: string;
  company?: string;
}) {
  const { data, error } = await supabase
    .from('attendees')
    .select('id')
    .eq('email', email)
    .eq('status', 'UNPAID')
    .maybeSingle();

  if (error && error.code !== 'PGRST116') {
    console.error('lookup attendee error', error);
    throw new Error('Unable to prepare attendee record.');
  }

  if (data?.id) {
    const { error: updateError } = await supabase
      .from('attendees')
      .update({
        pass_product_id: passProductId,
        attendee_role: attendeeRole,
        full_name: fullName,
        phone,
        company,
        metadata: {
          source: 'web',
          refreshed_at: new Date().toISOString(),
        },
      })
      .eq('id', data.id);

    if (updateError) {
      console.error('update attendee error', updateError);
      throw new Error('Unable to update attendee.');
    }
    return data.id as string;
  }

  const attendeeId = crypto.randomUUID();
  const { error: insertError } = await supabase.from('attendees').insert({
    id: attendeeId,
    pass_product_id: passProductId,
    attendee_role: attendeeRole,
    full_name: fullName,
    email,
    phone,
    company,
    status: 'UNPAID',
    metadata: {
      source: 'web',
    },
  });

  if (insertError) {
    console.error('insert attendee error', insertError);
    throw new Error('Unable to create attendee record.');
  }

  return attendeeId;
}
