import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchLatestAttendee(String userId) async {
    final data = await _client
        .from('attendees')
        .select('full_name, email, attendee_role, status, pass_products(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return Map<String, dynamic>.from(data as Map);
  }
}
