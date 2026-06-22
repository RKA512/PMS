/// Why the file exists:
/// Defines the official payment types supported by the financial isolation model.
/// Implements [Financial Rules FR-203] and [Business Rules BR-503].
/// Satisfies types: Incoming, Refund, Adjustment.
library;

enum PaymentType {
  incoming,
  refund,
  adjustment;

  String toJson() => name;

  static PaymentType fromJson(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentType.incoming,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentType.incoming:
        return 'دفعة واردة (Incoming)';
      case PaymentType.refund:
        return 'مسترجع (Refund)';
      case PaymentType.adjustment:
        return 'تعديل مالي (Adjustment)';
    }
  }
}
