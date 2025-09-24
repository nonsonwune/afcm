import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchLatestAttendee(String userId) async {
    final response = await _client
        .from('attendees')
        .select('full_name, email, attendee_role, status, pass_products(name)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response.error != null) {
      throw response.error!;
    }

    return response.data as Map<String, dynamic>?;
  }
}

