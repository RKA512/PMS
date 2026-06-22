/// Why the file exists:
/// Represents a single item/charge line within an Invoice.
/// Implements [Domain Model InvoiceLine] and financial precision rules.
library;

import '../../../../core/common/models/money.dart';

class InvoiceLine {
  final int? id;
  final int? invoiceId;
  final String description;
  final int quantity;
  final Money unitPrice;
  final Money lineTotal;

  const InvoiceLine({
    this.id,
    this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  /// Factory constructor that auto-calculates lineTotal from quantity and unitPrice.
  factory InvoiceLine.create({
    int? id,
    int? invoiceId,
    required String description,
    required int quantity,
    required Money unitPrice,
  }) {
    // lineTotal = quantity * unitPrice
    final total = unitPrice * quantity.toDouble();
    return InvoiceLine(
      id: id,
      invoiceId: invoiceId,
      description: description,
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: total,
    );
  }

  InvoiceLine copyWith({
    int? id,
    int? invoiceId,
    String? description,
    int? quantity,
    Money? unitPrice,
    Money? lineTotal,
  }) {
    return InvoiceLine(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }
}
