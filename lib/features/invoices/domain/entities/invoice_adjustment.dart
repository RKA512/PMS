/// Why the file exists:
/// Represents monetary adjustments (discount, manual adjustment, or corrections) on an Invoice.
/// Implements [Domain Model InvoiceAdjustment] and financial rules restricting modifications to Draft status.
library;

import '../../../../core/common/models/money.dart';

enum InvoiceAdjustmentType {
  discount,
  manual_adjustment,
  correction;

  String get displayName {
    switch (this) {
      case InvoiceAdjustmentType.discount:
        return 'خصم (Discount)';
      case InvoiceAdjustmentType.manual_adjustment:
        return 'تعديل يدوي (Manual Adjustment)';
      case InvoiceAdjustmentType.correction:
        return 'تصحيح (Correction)';
    }
  }

  static InvoiceAdjustmentType fromString(String value) {
    return InvoiceAdjustmentType.values.firstWhere(
      (e) => e.name == value || e.name.replaceAll('_', '') == value.replaceAll('_', ''),
      orElse: () => InvoiceAdjustmentType.manual_adjustment,
    );
  }
}

class InvoiceAdjustment {
  final int? id;
  final int? invoiceId;
  final InvoiceAdjustmentType adjustmentType;
  final Money amount;
  final String reason;
  final DateTime createdAt;

  const InvoiceAdjustment({
    this.id,
    this.invoiceId,
    required this.adjustmentType,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  InvoiceAdjustment copyWith({
    int? id,
    int? invoiceId,
    InvoiceAdjustmentType? adjustmentType,
    Money? amount,
    String? reason,
    DateTime? createdAt,
  }) {
    return InvoiceAdjustment(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      adjustmentType: adjustmentType ?? this.adjustmentType,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
