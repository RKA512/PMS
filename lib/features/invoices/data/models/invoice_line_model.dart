/// Why the file exists:
/// Maps the pure domain [InvoiceLine] entity to and from SQLite database map representations.
/// Implements [Data Model InvoiceLineModel] and preserves strong typing and integer minor units.
library;

import '../../../../core/common/models/money.dart';
import '../../domain/entities/invoice_line.dart';

class InvoiceLineModel {
  static Map<String, dynamic> toMap(InvoiceLine line) {
    return {
      if (line.id != null) 'id': line.id,
      if (line.invoiceId != null) 'invoice_id': line.invoiceId,
      'description': line.description,
      'quantity': line.quantity,
      'unit_price': line.unitPrice.minorUnits,
      'line_total': line.lineTotal.minorUnits,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static InvoiceLine fromMap(Map<String, dynamic> map) {
    return InvoiceLine(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int?,
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      unitPrice: Money(map['unit_price'] as int),
      lineTotal: Money(map['line_total'] as int),
    );
  }
}
