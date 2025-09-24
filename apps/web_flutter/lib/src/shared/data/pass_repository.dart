import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pass_product.dart';

class PassRepository {
  const PassRepository(this._client);

  final SupabaseClient _client;

  Future<List<PassProduct>> fetchActivePasses() async {
    final response = await _client
        .from('pass_products')
        .select()
        .eq('is_active', true)
        .order('amount_kobo');
    final data = response as List<dynamic>;
    return data
        .map((item) => PassProduct.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
