import 'package:supabase_flutter/supabase_flutter.dart';

class StaffRepository {
  const StaffRepository(this._client);

  final SupabaseClient _client;

  Future<bool> isStaff(String userId) async {
    final response = await _client.rpc('is_staff', params: {'p_uid': userId});
    if (response.error != null) {
      throw response.error!;
    }
    return (response.data as bool?) ?? false;
  }

  Future<List<StaffOrder>> fetchOrders({String? status}) async {
    dynamic query = _client
        .from('orders')
        .select(
          'id, status, amount_kobo, currency, created_at, paid_at, metadata, attendees(full_name, email), pass_products(name, sku)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((raw) => StaffOrder.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<List<StaffAttendee>> fetchAttendees({String? status}) async {
    dynamic query = _client
        .from('attendees')
        .select(
          'id, full_name, email, attendee_role, status, created_at, pass_products(name, sku), orders(id, status, paystack_invoice_url, paid_at)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    final response = await query;
    final data = response as List<dynamic>;
    return data
        .map((raw) =>
            StaffAttendee.fromMap(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  Future<void> markOrderPaid(String orderId, {String? note}) async {
    final response = await _client.rpc('mark_order_paid', params: {
      'p_order_id': orderId,
      if (note != null && note.isNotEmpty) 'p_note': note,
    });
    if (response.error != null) {
      throw response.error!;
    }
  }

  Future<void> markOrderFailed(String orderId, {String? reason}) async {
    final response = await _client.rpc('mark_order_failed', params: {
      'p_order_id': orderId,
      if (reason != null && reason.isNotEmpty) 'p_reason': reason,
    });
    if (response.error != null) {
      throw response.error!;
    }
  }
}

class StaffOrder {
  StaffOrder({
    required this.id,
    required this.status,
    required this.amountKobo,
    required this.currency,
    required this.createdAt,
    this.paidAt,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.passName,
    required this.passSku,
  });

  factory StaffOrder.fromMap(Map<String, dynamic> map) {
    final attendee =
        map['attendees'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final pass = map['pass_products'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return StaffOrder(
      id: map['id'] as String,
      status: (map['status'] ?? '') as String,
      amountKobo: map['amount_kobo'] as int,
      currency: (map['currency'] ?? 'NGN') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'] as String)
          : null,
      attendeeName: (attendee['full_name'] ?? 'Unknown') as String,
      attendeeEmail: (attendee['email'] ?? '') as String,
      passName: (pass['name'] ?? 'Unknown pass') as String,
      passSku: (pass['sku'] ?? '') as String,
    );
  }

  final String id;
  final String status;
  final int amountKobo;
  final String currency;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String attendeeName;
  final String attendeeEmail;
  final String passName;
  final String passSku;

  double get amountMajor => amountKobo / 100;
}

class StaffAttendee {
  StaffAttendee({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.passName,
    required this.passSku,
    required this.orders,
  });

  factory StaffAttendee.fromMap(Map<String, dynamic> map) {
    final pass = map['pass_products'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final ordersRaw = (map['orders'] as List<dynamic>?) ?? const [];
    return StaffAttendee(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? 'Pending name') as String,
      email: (map['email'] ?? '') as String,
      role: (map['attendee_role'] ?? '') as String,
      status: (map['status'] ?? 'UNPAID') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      passName: (pass['name'] ?? 'Unassigned') as String,
      passSku: (pass['sku'] ?? '') as String,
      orders: ordersRaw
          .map((raw) => StaffOrderSummary.fromMap(
                Map<String, dynamic>.from(raw as Map),
              ))
          .toList(),
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final DateTime createdAt;
  final String passName;
  final String passSku;
  final List<StaffOrderSummary> orders;
}

class StaffOrderSummary {
  const StaffOrderSummary({
    required this.id,
    required this.status,
    required this.invoiceUrl,
    this.paidAt,
  });

  factory StaffOrderSummary.fromMap(Map<String, dynamic> map) {
    return StaffOrderSummary(
      id: map['id'] as String,
      status: (map['status'] ?? '') as String,
      invoiceUrl: (map['paystack_invoice_url'] ?? '') as String,
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'] as String)
          : null,
    );
  }

  final String id;
  final String status;
  final String invoiceUrl;
  final DateTime? paidAt;
}
