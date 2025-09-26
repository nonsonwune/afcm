class CreateOrderPayload {
  const CreateOrderPayload({
    required this.passSku,
    required this.fullName,
    required this.email,
    required this.attendeeRole,
    this.phone,
    this.company,
    this.resendInvoice = false,
    this.currency = 'NGN',
    this.acceptedTerms = false,
    this.termsVersion,
  });

  final String passSku;
  final String fullName;
  final String email;
  final String attendeeRole;
  final String? phone;
  final String? company;
  final bool resendInvoice;
  final String currency;
  final bool acceptedTerms;
  final String? termsVersion;

  Map<String, dynamic> toJson() {
    return {
      'pass_sku': passSku,
      'full_name': fullName,
      'email': email,
      'attendee_role': attendeeRole,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (company != null && company!.isNotEmpty) 'company': company,
      'currency': currency,
      if (termsVersion != null) 'terms_version': termsVersion,
      if (acceptedTerms) 'accepted_terms': true,
      if (resendInvoice) 'resend_invoice': true,
    };
  }
}

class CreateOrderResult {
  const CreateOrderResult({
    required this.orderId,
    required this.attendeeId,
    required this.paymentRequestCode,
    required this.hostedLink,
    this.pdfUrl,
  });

  factory CreateOrderResult.fromMap(Map<String, dynamic> map) {
    return CreateOrderResult(
      orderId: map['order_id'] as String,
      attendeeId: map['attendee_id'] as String,
      paymentRequestCode: map['payment_request_code'] as String,
      hostedLink: (map['hosted_link'] ?? '') as String,
      pdfUrl: map['pdf_url'] as String?,
    );
  }

  final String orderId;
  final String attendeeId;
  final String paymentRequestCode;
  final String hostedLink;
  final String? pdfUrl;
}
