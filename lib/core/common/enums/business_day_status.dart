/// Why the file exists:
/// Defines the open/closed state of a Business Day for operations log.
/// Implements [Domain Model BusinessDay] and [Business Rules Section 13].
library;

enum BusinessDayStatus {
  open,
  closed;

  String toJson() => name;

  static BusinessDayStatus fromJson(String value) {
    return BusinessDayStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BusinessDayStatus.open,
    );
  }

  String get displayName {
    switch (this) {
      case BusinessDayStatus.open:
        return 'مفتوح (Open)';
      case BusinessDayStatus.closed:
        return 'مغلق (Closed)';
    }
  }
}
