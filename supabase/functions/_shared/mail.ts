import { Resend } from './deps.ts';
import { type MailConfig } from './config.ts';

export interface MailContent {
  to: string;
  subject: string;
  html: string;
  text?: string;
  attachments?: Array<{ filename: string; content: string; type: string }>;
}

export async function sendMail(
  content: MailContent,
  config: MailConfig,
): Promise<void> {
  if (!config.resendApiKey) {
    console.warn('RESEND_API_KEY missing; email send skipped.');
    return;
  }

  const resend = new Resend(config.resendApiKey);
  const response = await resend.emails.send({
    from: config.fromAddress,
    to: content.to,
    subject: content.subject,
    html: content.html,
    text: content.text,
    attachments: content.attachments?.map((attachment) => ({
      filename: attachment.filename,
      content: attachment.content,
      type: attachment.type,
    })),
  });

  if (response.error) {
    throw new Error(`Failed to send email: ${response.error.message}`);
  }
}

