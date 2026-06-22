/// Why the file exists:
/// Defines the official lifecycle statuses for any Settlement in the PMS.
/// Implements [Financial Rules FR-602], [Business Rules BR-702], and [Design Decisions DD-013].
/// Satisfies statuses: Pending, Completed, Cancelled.
library;

enum SettlementStatus {
  pending,
  completed,
  cancelled;

  String toJson() => name;

  static SettlementStatus fromJson(String value) {
    return SettlementStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SettlementStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case SettlementStatus.pending:
        return 'معلق (Pending)';
      case SettlementStatus.completed:
        return 'مكتمل (Completed)';
      case SettlementStatus.cancelled:
        return 'ملغي (Cancelled)';
    }
  }
}
