import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/order_models.dart';

class RegistrationRepository {
  const RegistrationRepository(this._client);

  final SupabaseClient _client;

  Future<CreateOrderResult> createOrder(CreateOrderPayload payload) async {
    final response = await _client.functions.invoke('create-order', body: payload.toJson());
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['status'] != 'ok') {
      throw Exception(data?['message'] ?? 'Unable to create order');
    }
    final payloadData = data['data'] as Map<String, dynamic>;
    return CreateOrderResult.fromMap(payloadData);
  }

  Future<CreateOrderResult> resendInvoice(CreateOrderPayload payload) async {
    final body = payload.toJson();
    body['resend_invoice'] = true;
    final response = await _client.functions.invoke('create-order', body: body);
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    final data = response.data as Map<String, dynamic>?;
    if (data == null || data['status'] != 'ok') {
      throw Exception(data?['message'] ?? 'Unable to resend invoice');
    }
    return CreateOrderResult.fromMap(data['data'] as Map<String, dynamic>);
  }
}
