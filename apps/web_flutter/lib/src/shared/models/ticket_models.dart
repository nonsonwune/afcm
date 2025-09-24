import 'dart:convert';

class Ticket {
  const Ticket({
    required this.id,
    required this.serialNumber,
    required this.passName,
    required this.validFrom,
    required this.validTo,
    required this.qrPayload,
    required this.qrChecksum,
    required this.qrDataUrl,
    this.icsBase64,
  });

  factory Ticket.fromMap(Map<String, dynamic> map) {
    final metadata = map['metadata'] != null
        ? Map<String, dynamic>.from(map['metadata'] as Map)
        : <String, dynamic>{};
    final payload = map['qr_payload'] != null
        ? Map<String, dynamic>.from(map['qr_payload'] as Map)
        : <String, dynamic>{};
    final passName = (map['pass_products']?['name'] as String?) ??
        (map['pass_name'] as String?) ??
        '';

    return Ticket(
      id: map['id'] as String,
      serialNumber: map['serial_number'] as String,
      passName: passName,
      validFrom: DateTime.parse(map['valid_from'] as String),
      validTo: DateTime.parse(map['valid_to'] as String),
      qrPayload: payload,
      qrChecksum: (map['qr_checksum'] ?? '') as String,
      qrDataUrl: (metadata['qr_data_url'] as String?) ?? '',
      icsBase64: map['ics_base64'] as String?,
    );
  }

  final String id;
  final String serialNumber;
  final String passName;
  final DateTime validFrom;
  final DateTime validTo;
  final Map<String, dynamic> qrPayload;
  final String qrChecksum;
  final String qrDataUrl;
  final String? icsBase64;

  String get payloadJson => qrPayload.isEmpty ? '{}' : jsonEncode(qrPayload);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'pass_name': passName,
      'valid_from': validFrom.toIso8601String(),
      'valid_to': validTo.toIso8601String(),
      'qr_payload': qrPayload,
      'qr_checksum': qrChecksum,
      'qr_data_url': qrDataUrl,
      'ics_base64': icsBase64,
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      serialNumber: json['serial_number'] as String,
      passName: (json['pass_name'] ?? '') as String,
      validFrom: DateTime.parse(json['valid_from'] as String),
      validTo: DateTime.parse(json['valid_to'] as String),
      qrPayload: json['qr_payload'] != null
          ? Map<String, dynamic>.from(json['qr_payload'] as Map)
          : <String, dynamic>{},
      qrChecksum: (json['qr_checksum'] ?? '') as String,
      qrDataUrl: (json['qr_data_url'] ?? '') as String,
      icsBase64: json['ics_base64'] as String?,
    );
  }
}
