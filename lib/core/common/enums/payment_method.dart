/// Why the file exists:
/// Defines the official payment methods supported by the PMS.
/// Implements [Business Rules BR-607] and [Flow 24] indicating GuestCredit is a Payment Method, not a Payment Type.
library;

enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  guestCredit;

  String toJson() => name;

  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PaymentMethod.cash,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدي (Cash)';
      case PaymentMethod.card:
        return 'بطاقة (Card)';
      case PaymentMethod.bankTransfer:
        return 'تحويل بنكي (Bank Transfer)';
      case PaymentMethod.guestCredit:
        return 'رصيد دائن للنزيل (Guest Credit)';
    }
  }
}
