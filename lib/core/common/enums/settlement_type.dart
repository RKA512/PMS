/// Why the file exists:
/// Defines the official types of Settlements.
/// Implements [Financial Rules FR-600, FR-601] and [Final Design Decisions DD-016].
/// Strictly establishes that only 'Overpayment' and 'Underpayment' are valid types. 'Adjustment' is FORBIDDEN.
library;

enum SettlementType {
  overpayment,
  underpayment;

  String toJson() => name;

  static SettlementType fromJson(String value) {
    return SettlementType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SettlementType.overpayment,
    );
  }

  String get displayName {
    switch (this) {
      case SettlementType.overpayment:
        return 'دفع زائد (Overpayment)';
      case SettlementType.underpayment:
        return 'دفع ناقص (Underpayment)';
    }
  }
}
