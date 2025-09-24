class PassProduct {
  const PassProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.amountKobo,
    required this.currency,
    required this.displayAmountUsd,
    required this.validStartDay,
    required this.validEndDay,
    required this.isEarlyBird,
  });

  factory PassProduct.fromMap(Map<String, dynamic> map) {
    return PassProduct(
      id: map['id'] as String,
      sku: map['sku'] as String,
      name: map['name'] as String,
      description: (map['description'] ?? '') as String,
      amountKobo: map['amount_kobo'] as int,
      currency: (map['currency'] ?? 'NGN') as String,
      displayAmountUsd: (map['display_amount_usd'] as num?)?.toDouble(),
      validStartDay: map['valid_start_day'] as int,
      validEndDay: map['valid_end_day'] as int,
      isEarlyBird: (map['is_early_bird'] ?? false) as bool,
    );
  }

  final String id;
  final String sku;
  final String name;
  final String description;
  final int amountKobo;
  final String currency;
  final double? displayAmountUsd;
  final int validStartDay;
  final int validEndDay;
  final bool isEarlyBird;

  double get amountNaira => amountKobo / 100;

  String get validityLabel {
    if (validStartDay == validEndDay) {
      return 'Valid for Day $validStartDay';
    }
    return 'Valid for Days $validStartDay–$validEndDay';
  }
}
