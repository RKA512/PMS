/// Why the file exists:
/// Defines the official states of an Invoice in the PMS.
/// Implements [Final Design Decisions DD-010], [Business Rules BR-401], and [Financial Rules FR-401].
/// Satisfies states: Draft, Issued, PartiallyPaid, Paid, Cancelled.
library;

enum InvoiceStatus {
  draft,
  issued,
  partiallyPaid,
  paid,
  cancelled;

  String toJson() => name;

  static InvoiceStatus fromJson(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => InvoiceStatus.draft,
    );
  }

  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'مسودة (Draft)';
      case InvoiceStatus.issued:
        return 'صادرة (Issued)';
      case InvoiceStatus.partiallyPaid:
        return 'مدفوعة جزئياً (Partially Paid)';
      case InvoiceStatus.paid:
        return 'مدفوعة (Paid)';
      case InvoiceStatus.cancelled:
        return 'ملغاة (Cancelled)';
    }
  }
}
