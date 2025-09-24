import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/ticket_models.dart';

class TicketRepository {
  TicketRepository(this._client);

  final SupabaseClient _client;

  Future<Ticket?> fetchLatestTicket() async {
    final data = await _client
        .from('tickets')
        .select(
          'id, serial_number, valid_from, valid_to, qr_payload, qr_checksum, ics_base64, metadata, pass_products(name)',
        )
        .isFilter('revoked_at', null)
        .order('issued_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Ticket.fromMap(Map<String, dynamic>.from(data as Map));
  }

  Future<void> claimAttendeeRecords(String email) async {
    if (email.isEmpty) return;
    await _client.rpc('claim_attendee_records', params: {'claim_email': email});
  }
}
