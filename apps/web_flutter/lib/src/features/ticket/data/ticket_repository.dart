import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/ticket_models.dart';

class TicketRepository {
  TicketRepository(this._client);

  final SupabaseClient _client;

  Future<Ticket?> fetchLatestTicket() async {
    final response = await _client
        .from('tickets')
        .select(
          'id, serial_number, valid_from, valid_to, qr_payload, qr_checksum, ics_base64, metadata, pass_products(name)',
        )
        .is_('revoked_at', null)
        .order('issued_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response.error != null) {
      throw response.error!;
    }

    final data = response.data;
    if (data == null) {
      return null;
    }

    return Ticket.fromMap(data as Map<String, dynamic>);
  }

  Future<void> claimAttendeeRecords(String email) async {
    if (email.isEmpty) return;
    await _client.rpc('claim_attendee_records', params: {'claim_email': email});
  }
}
