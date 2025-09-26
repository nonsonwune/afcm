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
  currency?: string;
  accepted_terms?: boolean;
  terms_version?: string;
}

interface JsonResponse {
  status: 'ok' | 'error';
  message: string;
  data?: Record<string, unknown>;
}

const config = loadConfig();
const supabase = getSupabaseClient();

const ALLOWED_CURRENCIES = ['NGN', 'USD'] as const;

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

    const currencyPreference = (input.currency ?? passProduct.currency).toUpperCase();

    const registrationMetadata = {
      attendee_role: input.attendee_role,
      attendee_email: email,
      attendee_name: input.full_name,
      pass_sku: passSku,
      currency_preference: currencyPreference,
      terms_version: input.terms_version ?? null,
      accepted_terms: Boolean(input.accepted_terms),
    };

    const { data: registrationData, error: registrationError } = await supabase
      .rpc('create_pending_registration', {
        p_pass_product_id: passProduct.id,
        p_attendee_role: input.attendee_role,
        p_full_name: input.full_name,
        p_email: email,
        p_phone: input.phone ?? null,
        p_company: input.company ?? null,
        p_currency: passProduct.currency,
        p_amount_kobo: passProduct.amount_kobo,
        p_metadata: registrationMetadata,
      });

    if (registrationError) {
      console.error('registration rpc error', registrationError);
      throw new Error('Unable to prepare attendee registration.');
    }

    const registrationRow = Array.isArray(registrationData)
      ? (registrationData[0] as { attendee_id: string; order_id: string } | undefined)
      : (registrationData as { attendee_id: string; order_id: string } | undefined);

    if (!registrationRow) {
      throw new Error('Registration could not be created.');
    }

    const attendeeId = registrationRow.attendee_id;
    const orderId = registrationRow.order_id;

    const expiresAt = dayjs().add(48, 'hour').toISOString();

    const description = `${passProduct.name} – AFCM 2025`;

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
          currency_preference: currencyPreference,
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

  const currency = (payload.currency ?? 'NGN').toUpperCase();
  if (!ALLOWED_CURRENCIES.includes(currency as typeof ALLOWED_CURRENCIES[number])) {
    return 'Unsupported currency selection.';
  }

  if (!payload.resend_invoice) {
    if (!payload.accepted_terms) {
      return 'Terms must be accepted before continuing.';
    }
    if (!payload.terms_version || payload.terms_version.trim().length === 0) {
      return 'Missing terms version.';
    }
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
