import { crypto } from './deps.ts';

interface TicketPayload {
  ticketId: string;
  attendeeId: string;
  orderId: string;
  validFrom: string;
  validTo: string;
  checksum: string;
}

export async function createSignedTicketPayload(
  payload: Omit<TicketPayload, 'checksum'>,
  secret: string,
): Promise<TicketPayload> {
  const encoder = new TextEncoder();
  const data = `${payload.ticketId}:${payload.attendeeId}:${payload.orderId}:${payload.validFrom}:${payload.validTo}`;
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, encoder.encode(data));
  const checksum = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');

  return { ...payload, checksum };
}

