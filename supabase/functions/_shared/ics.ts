import { base64Encode, dayjs, dayjsUtcPlugin, dayjsTimezonePlugin } from './deps.ts';

dayjs.extend(dayjsUtcPlugin);
dayjs.extend(dayjsTimezonePlugin);

export interface TicketIcsInput {
  attendeeName: string;
  attendeeEmail: string;
  passName: string;
  eventStartsAt: string;
  eventEndsAt: string;
  siteUrl: string;
  timezone: string;
}

export function buildTicketIcs({
  attendeeName,
  attendeeEmail,
  passName,
  eventStartsAt,
  eventEndsAt,
  siteUrl,
  timezone,
}: TicketIcsInput) {
  const start = dayjs(eventStartsAt).tz(timezone);
  const end = dayjs(eventEndsAt).tz(timezone);
  const uid = crypto.randomUUID();

  const icsLines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//AFCM//Tickets//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `SUMMARY:${passName} - AFCM`,
    `DTSTART;TZID=${timezone}:${start.format('YYYYMMDDTHHmmss')}`,
    `DTEND;TZID=${timezone}:${end.format('YYYYMMDDTHHmmss')}`,
    `DTSTAMP:${dayjs.utc().format('YYYYMMDDTHHmmss')}Z`,
    `DESCRIPTION:Keep this ticket handy. View ticket: ${siteUrl}/me/ticket`,
    `URL:${siteUrl}/me/ticket`,
    `ATTENDEE;CN=${attendeeName};ROLE=REQ-PARTICIPANT:mailto:${attendeeEmail}`,
    'END:VEVENT',
    'END:VCALENDAR',
  ];

  const raw = icsLines.join('\r\n');
  const base64Content = base64Encode(new TextEncoder().encode(raw));
  return { raw, base64Content };
}

