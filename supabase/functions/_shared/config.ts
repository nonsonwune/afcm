export interface PaystackConfig {
  secretKey: string;
  baseUrl: string;
}

export interface MailConfig {
  resendApiKey?: string;
  fromAddress: string;
}

export interface RuntimeConfig {
  siteUrl: string;
  timezone: string;
  qrSecret: string;
  paystack: PaystackConfig;
  mail: MailConfig;
}

export function loadConfig(): RuntimeConfig {
  const paystackSecret = Deno.env.get('PAYSTACK_SECRET_KEY');
  const siteUrl = Deno.env.get('SITE_URL');
  const timezone = Deno.env.get('TZ') ?? 'Africa/Lagos';
  const qrSecret = Deno.env.get('QR_SECRET');
  const mailFrom = Deno.env.get('EMAIL_FROM') ?? 'AFCM Tickets <tickets@example.com>';
  const resendApiKey = Deno.env.get('RESEND_API_KEY');

  if (!paystackSecret) {
    throw new Error('Missing PAYSTACK_SECRET_KEY');
  }
  if (!siteUrl) {
    throw new Error('Missing SITE_URL');
  }
  if (!qrSecret) {
    throw new Error('Missing QR_SECRET');
  }

  return {
    siteUrl,
    timezone,
    qrSecret,
    paystack: {
      secretKey: paystackSecret,
      baseUrl: 'https://api.paystack.co',
    },
    mail: {
      resendApiKey,
      fromAddress: mailFrom,
    },
  };
}

