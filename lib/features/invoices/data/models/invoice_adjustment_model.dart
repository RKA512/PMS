/// Why the file exists:
/// Maps the pure domain [InvoiceAdjustment] entity to and from SQLite database map representations.
/// Implements [Data Model InvoiceAdjustmentModel] supporting official types: discount, manual_adjustment, correction.
library;

import '../../../../core/common/models/money.dart';
import '../../domain/entities/invoice_adjustment.dart';

class InvoiceAdjustmentModel {
  static Map<String, dynamic> toMap(InvoiceAdjustment adjustment) {
    return {
      if (adjustment.id != null) 'id': adjustment.id,
      if (adjustment.invoiceId != null) 'invoice_id': adjustment.invoiceId,
      'adjustment_type': adjustment.adjustmentType.name,
      'amount': adjustment.amount.minorUnits,
      'reason': adjustment.reason,
      'created_at': adjustment.createdAt.toIso8601String(),
    };
  }

  static InvoiceAdjustment fromMap(Map<String, dynamic> map) {
    return InvoiceAdjustment(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      adjustmentType: InvoiceAdjustmentType.fromString(map['adjustment_type'] as String),
      amount: Money(map['amount'] as int),
      reason: map['reason'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
