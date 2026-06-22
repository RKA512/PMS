/// Why the file exists:
/// Represents currency structure for properties.
/// Implements [Domain Model Currency] and [Final Design Decisions DD-017 / DD-018].
/// Prepares structural support for Post-MVP multi-currency without breaking single currency flow in MVP.
library;

class Currency {
  final int? id;
  final String code;
  final String name;
  final String symbol;
  final bool isDefault;

  const Currency({
    this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'] as int?,
      code: map['code'] as String,
      name: map['name'] as String,
      symbol: map['symbol'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}
