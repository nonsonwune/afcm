import { type PaystackConfig } from './config.ts';

interface PaystackRequestInit extends RequestInit {
  path: string;
}

async function paystackFetch<T>(
  { path, ...init }: PaystackRequestInit,
  config: PaystackConfig,
): Promise<T> {
  const response = await fetch(`${config.baseUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${config.secretKey}`,
      ...(init.headers ?? {}),
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Paystack request failed: ${response.status} ${text}`);
  }

  return (await response.json()) as T;
}

export interface PaymentRequestPayload {
  customer: string;
  amount: number;
  currency?: string;
  description?: string;
  due_date?: string;
  invoice_limit?: number;
  metadata?: Record<string, unknown>;
  line_items?: Array<{ name: string; amount: number; quantity?: number }>;
}

export interface PaymentRequestResponse {
  status: boolean;
  message: string;
  data: {
    id: number;
    request_code: string;
    status: string;
    amount: number;
    currency: string;
    due_date: string;
    pdf_url: string;
    hosted_link: string;
  };
}

export function createPaymentRequest(
  payload: PaymentRequestPayload,
  config: PaystackConfig,
) {
  return paystackFetch<PaymentRequestResponse>(
    {
      path: '/paymentrequest',
      method: 'POST',
      body: JSON.stringify(payload),
    },
    config,
  );
}

export interface PaymentRequestVerifyResponse {
  status: boolean;
  message: string;
  data: {
    request_code: string;
    status: string;
    paid: boolean;
    paid_at: string | null;
    amount: number;
    currency: string;
    email: string;
    hosted_link: string;
    invoice_number: string;
  };
}

export function verifyPaymentRequest(code: string, config: PaystackConfig) {
  return paystackFetch<PaymentRequestVerifyResponse>(
    {
      path: `/paymentrequest/verify/${code}`,
      method: 'GET',
    },
    config,
  );
}

export function sendPaymentRequest(code: string, config: PaystackConfig) {
  return paystackFetch<{ status: boolean; message: string }>(
    {
      path: `/paymentrequest/notify/${code}`,
      method: 'POST',
    },
    config,
  );
}

