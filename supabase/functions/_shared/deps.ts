export { crypto } from 'https://deno.land/std@0.224.0/crypto/mod.ts';
export { encode as base64Encode, decode as base64Decode } from 'https://deno.land/std@0.224.0/encoding/base64.ts';
export { encode as base64UrlEncode } from 'https://deno.land/std@0.224.0/encoding/base64url.ts';
export { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.1';
export type {
  SupabaseClient,
  PostgrestSingleResponse,
} from 'https://esm.sh/@supabase/supabase-js@2.45.1';
export { Resend } from 'https://esm.sh/resend@3.2.0';
export { default as dayjs } from 'https://esm.sh/dayjs@1.11.11';
export dayjsUtcPlugin from 'https://esm.sh/dayjs@1.11.11/plugin/utc.js';
export dayjsTimezonePlugin from 'https://esm.sh/dayjs@1.11.11/plugin/timezone.js';
export * as QRCode from 'https://esm.sh/qrcode@1.5.3';
