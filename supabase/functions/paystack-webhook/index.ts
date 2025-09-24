import { loadConfig } from '../_shared/config.ts';
import { dayjs, dayjsTimezonePlugin, dayjsUtcPlugin } from '../_shared/deps.ts';
import { buildTicketIcs } from '../_shared/ics.ts';
import { sendMail } from '../_shared/mail.ts';
import { createSignedTicketPayload } from '../_shared/qr.ts';
import { generateQrPngBase64 } from '../_shared/qr_image.ts';
import { verifyPaymentRequest } from '../_shared/paystack.ts';
import { getSupabaseClient } from '../_shared/supabase.ts';

import { crypto } from '../_shared/deps.ts';

dayjs.extend(dayjsUtcPlugin);
dayjs.extend(dayjsTimezonePlugin);

const config = loadConfig();
const supabase = getSupabaseClient();

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const signature = req.headers.get('x-paystack-signature');
  const rawBody = await req.text();

  if (!(await verifySignature(rawBody, signature, config.paystack.secretKey))) {
    return new Response('Invalid signature', { status: 401 });
  }

  try {
    const payload = JSON.parse(rawBody) as Record<string, unknown>;
    const data = payload['data'] as Record<string, unknown> | undefined;
    const requestCode = (data?.['request_code'] ?? data?.['payment_request_code']) as string | undefined;

    if (!requestCode) {
      console.warn('No request code in payload');
      return new Response('ok', { status: 200 });
    }

    const verification = await verifyPaymentRequest(requestCode, config.paystack);
    if (!verification.data.paid) {
      console.log('Invoice not paid yet', requestCode);
      return new Response('ignored', { status: 200 });
    }

    const order = await fetchOrderByRequestCode(requestCode);
    if (!order) {
      console.warn(`Order not found for request code ${requestCode}`);
      return new Response('ok', { status: 200 });
    }

    if (order.status === 'paid') {
      console.log('Order already processed', order.id);
      return new Response('ok', { status: 200 });
    }

    const attendee = await fetchAttendee(order.attendee_id);
    const passProduct = await fetchPass(order.pass_product_id);
    const { timezone, site_url } = await fetchEventSettings();
    const eventWindow = await computePassWindow(passProduct.valid_start_day, passProduct.valid_end_day);

    if (!eventWindow) {
      throw new Error('Unable to compute ticket validity window.');
    }

    const { validFrom, validTo } = eventWindow;

    const { data: serialData, error: serialError } = await supabase.rpc('generate_ticket_serial');
    if (serialError) {
      console.error('serial generation error', serialError);
      throw new Error('Unable to generate ticket serial.');
    }
    const serial = serialData as string;

    const ticketId = crypto.randomUUID();
    const qrPayload = await createSignedTicketPayload(
      {
        ticketId,
        attendeeId: attendee.id,
        orderId: order.id,
        validFrom,
        validTo,
      },
      config.qrSecret,
    );

    const qrString = JSON.stringify(qrPayload);
    const qrDataUrl = await generateQrPngBase64(qrString);

    const { raw: icsRaw, base64Content: icsBase64 } = buildTicketIcs({
      attendeeName: attendee.full_name,
      attendeeEmail: attendee.email,
      passName: passProduct.name,
      eventStartsAt: validFrom,
      eventEndsAt: validTo,
      siteUrl: site_url,
      timezone,
    });

    const nowIso = dayjs().toISOString();

    const { error: orderUpdateError } = await supabase
      .from('orders')
      .update({
        status: 'paid',
        paid_at: nowIso,
        paystack_meta: verification.data,
      })
      .eq('id', order.id)
      .eq('status', 'pending');

    if (orderUpdateError) {
      console.error('order update error', orderUpdateError);
      throw new Error('Unable to mark order as paid.');
    }

    const { error: attendeeUpdateError } = await supabase
      .from('attendees')
      .update({
        status: 'PAID',
        pass_product_id: passProduct.id,
      })
      .eq('id', attendee.id);

    if (attendeeUpdateError) {
      console.error('attendee update error', attendeeUpdateError);
      throw new Error('Unable to update attendee.');
    }

    const { data: existingTicket } = await supabase
      .from('tickets')
      .select('id')
      .eq('order_id', order.id)
      .maybeSingle();

    if (!existingTicket) {
      const { error: ticketInsertError } = await supabase.from('tickets').insert({
        id: ticketId,
        attendee_id: attendee.id,
        order_id: order.id,
        pass_product_id: passProduct.id,
        serial_number: serial,
        qr_payload: qrPayload,
        qr_checksum: qrPayload.checksum,
        valid_from: validFrom,
        valid_to: validTo,
        ics_base64: icsBase64,
        metadata: {
          qr_data_url: qrDataUrl,
        },
      });

      if (ticketInsertError) {
        console.error('ticket insert error', ticketInsertError);
        throw new Error('Unable to issue ticket.');
      }
    }

    await supabase.from('notifications').insert({
      recipient_email: attendee.email,
      subject: `Your AFCM ticket – ${passProduct.name}`,
      body_html: buildTicketHtml({
        attendeeName: attendee.full_name,
        passName: passProduct.name,
        hostedLink: order.paystack_invoice_url,
        ticketUrl: `${site_url}/me/ticket`,
        qrDataUrl,
        validFrom,
        validTo,
        timezone,
      }),
      body_text: buildTicketText({
        attendeeName: attendee.full_name,
        passName: passProduct.name,
        ticketUrl: `${site_url}/me/ticket`,
        validFrom,
        validTo,
        timezone,
      }),
      status: 'pending',
      metadata: {
        type: 'ticket_issued',
        order_id: order.id,
        attendee_id: attendee.id,
        ticket_id: ticketId,
      },
    });

    await sendMail(
      {
        to: attendee.email,
        subject: `Your AFCM ticket – ${passProduct.name}`,
        html: buildTicketHtml({
          attendeeName: attendee.full_name,
          passName: passProduct.name,
          hostedLink: order.paystack_invoice_url,
          ticketUrl: `${site_url}/me/ticket`,
          qrDataUrl,
          validFrom,
          validTo,
          timezone,
        }),
        text: buildTicketText({
          attendeeName: attendee.full_name,
          passName: passProduct.name,
          ticketUrl: `${site_url}/me/ticket`,
          validFrom,
          validTo,
          timezone,
        }),
        attachments: [
          {
            filename: 'afcm-ticket.ics',
            type: 'text/calendar',
            content: icsBase64,
          },
        ],
      },
      config.mail,
    );

    return new Response('ok', { status: 200 });
  } catch (error) {
    console.error('paystack webhook error', error);
    return new Response('error', { status: 500 });
  }
});

async function verifySignature(body: string, signature: string | null, secret: string) {
  if (!signature) return false;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-512' },
    false,
    ['sign'],
  );
  const signed = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
  const computed = Array.from(new Uint8Array(signed))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return computed === signature;
}

async function fetchOrderByRequestCode(requestCode: string) {
  const { data, error } = await supabase
    .from('orders')
    .select('id, attendee_id, pass_product_id, status, paystack_invoice_url')
    .eq('paystack_request_code', requestCode)
    .maybeSingle();

  if (error) {
    console.error('order lookup error', error);
    throw new Error('Unable to lookup order.');
  }

  return data;
}

async function fetchAttendee(attendeeId: string) {
  const { data, error } = await supabase
    .from('attendees')
    .select('id, full_name, email, attendee_role')
    .eq('id', attendeeId)
    .single();

  if (error) {
    console.error('attendee fetch error', error);
    throw new Error('Unable to fetch attendee.');
  }
  return data;
}

async function fetchPass(passId: string) {
  const { data, error } = await supabase
    .from('pass_products')
    .select('id, name, valid_start_day, valid_end_day')
    .eq('id', passId)
    .single();

  if (error) {
    console.error('pass fetch error', error);
    throw new Error('Unable to fetch pass product.');
  }
  return data;
}

async function fetchEventSettings() {
  const { data, error } = await supabase
    .from('event_settings')
    .select('timezone, site_url')
    .eq('id', 1)
    .maybeSingle();

  if (error || !data) {
    console.error('event settings fetch error', error);
    throw new Error('Unable to fetch event settings.');
  }

  return data as { timezone: string; site_url: string };
}

async function computePassWindow(startDay: number, endDay: number) {
  const { data, error } = await supabase
    .from('event_days')
    .select('day_number, doors_open, doors_close')
    .in('day_number', [startDay, endDay]);

  if (error) {
    console.error('event days fetch error', error);
    throw new Error('Unable to fetch event days.');
  }

  const start = data?.find((d) => d.day_number === startDay);
  const end = data?.find((d) => d.day_number === endDay);

  if (!start || !end) {
    return null;
  }

  return {
    validFrom: start.doors_open,
    validTo: end.doors_close,
  };
}

function buildTicketHtml({
  attendeeName,
  passName,
  ticketUrl,
  qrDataUrl,
  validFrom,
  validTo,
  timezone,
  hostedLink,
}: {
  attendeeName: string;
  passName: string;
  ticketUrl: string;
  qrDataUrl: string;
  validFrom: string;
  validTo: string;
  timezone: string;
  hostedLink?: string | null;
}) {
  const formattedFrom = dayjs(validFrom).tz(timezone).format('dddd, MMM D · h:mm A');
  const formattedTo = dayjs(validTo).tz(timezone).format('dddd, MMM D · h:mm A');

  return `
  <div style="font-family: Arial, sans-serif; color: #111827;">
    <h1 style="color:#0B3D91;">${passName} confirmed</h1>
    <p>Hi ${attendeeName.split(' ')[0]},</p>
    <p>Your payment is confirmed. Present this QR at check-in:</p>
    <div style="text-align:center; margin:24px 0;">
      <img src="${qrDataUrl}" alt="AFCM ticket QR" style="max-width:220px;" />
    </div>
    <p><strong>Valid:</strong> ${formattedFrom} – ${formattedTo} (${timezone})</p>
    <p><a href="${ticketUrl}">Open your ticket</a> (works offline inside the AFCM PWA).</p>
    ${hostedLink ? `<p>If you still need the Paystack invoice, <a href="${hostedLink}">view it here</a>.</p>` : ''}
    <p style="margin-top:32px;">See you at AFCM!</p>
  </div>
  `;
}

function buildTicketText({
  attendeeName,
  passName,
  ticketUrl,
  validFrom,
  validTo,
  timezone,
}: {
  attendeeName: string;
  passName: string;
  ticketUrl: string;
  validFrom: string;
  validTo: string;
  timezone: string;
}) {
  const formattedFrom = dayjs(validFrom).tz(timezone).format('ddd, MMM D · h:mm A');
  const formattedTo = dayjs(validTo).tz(timezone).format('ddd, MMM D · h:mm A');

  return `Hi ${attendeeName.split(' ')[0]},\n\n`
    + `${passName} confirmed. Show the QR in the AFCM app.\n`
    + `Valid: ${formattedFrom} – ${formattedTo} (${timezone}).\n`
    + `View ticket: ${ticketUrl}`;
}
