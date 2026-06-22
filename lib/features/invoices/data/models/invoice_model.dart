/// Why the file exists:
/// Maps the pure domain [Invoice] entity to and from SQLite database map representations.
/// Implements [Data Model InvoiceModel] with strong types, mapping raw fields to Money, InvoiceStatus, etc.
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';

class InvoiceModel {
  static Map<String, dynamic> toMap(Invoice invoice) {
    return {
      if (invoice.id != null) 'id': invoice.id,
      'uuid': invoice.uuid,
      'booking_id': invoice.bookingId,
      'invoice_number': invoice.invoiceNumber,
      'total_amount': invoice.totalAmount.minorUnits,
      'status': invoice.status.name, // official status
      'issued_at': invoice.issuedAt?.toIso8601String(),
      'created_at': invoice.createdAt.toIso8601String(),
      'updated_at': invoice.updatedAt.toIso8601String(),
    };
  }

  static Invoice fromMap(
    Map<String, dynamic> map, {
    List<InvoiceLine> lines = const [],
    List<InvoiceAdjustment> adjustments = const [],
  }) {
    return Invoice(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      bookingId: map['booking_id'] as int,
      invoiceNumber: map['invoice_number'] as String,
      totalAmount: Money(map['total_amount'] as int),
      status: InvoiceStatus.fromJson(map['status'] as String),
      issuedAt: map['issued_at'] != null ? DateTime.parse(map['issued_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lines: lines,
      adjustments: adjustments,
    );
  }
}
