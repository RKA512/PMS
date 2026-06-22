/// Why the file exists:
/// Represents the parent Invoice entity containing its lines, adjustments, and status.
/// Implements [Domain Model Invoice] and strict financial rules.
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import 'invoice_adjustment.dart';
import 'invoice_line.dart';

class Invoice {
  final int? id;
  final String uuid;
  final int bookingId;
  final String invoiceNumber;
  final Money totalAmount;
  final InvoiceStatus status;
  final DateTime? issuedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InvoiceLine> lines;
  final List<InvoiceAdjustment> adjustments;

  const Invoice({
    this.id,
    required this.uuid,
    required this.bookingId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.status,
    this.issuedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lines,
    required this.adjustments,
  });

  /// Calculates the raw subtotal of all invoice lines (sum of line_totals).
  Money get subtotal {
    int sum = 0;
    for (final line in lines) {
      sum += line.lineTotal.minorUnits;
    }
    return Money(sum);
  }

  /// Calculates the sum of all adjustments.
  /// Disocunts subtract from total, other adjustment types add to the total.
  Money get totalAdjustments {
    int sum = 0;
    for (final adj in adjustments) {
      if (adj.adjustmentType == InvoiceAdjustmentType.discount) {
        sum -= adj.amount.minorUnits.abs(); // Deduct discount
      } else {
        sum += adj.amount.minorUnits; // Add other adjustments / corrections
      }
    }
    return Money(sum);
  }

  /// Calculates the total invoice amount based on lines and adjustments.
  Money get calculatedTotal {
    final sub = subtotal;
    final adj = totalAdjustments;
    final finalMinorStr = sub.minorUnits + adj.minorUnits;
    return Money(finalMinorStr < 0 ? 0 : finalMinorStr);
  }

  Invoice copyWith({
    int? id,
    String? uuid,
    int? bookingId,
    String? invoiceNumber,
    Money? totalAmount,
    InvoiceStatus? status,
    DateTime? issuedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<InvoiceLine>? lines,
    List<InvoiceAdjustment>? adjustments,
  }) {
    return Invoice(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      bookingId: bookingId ?? this.bookingId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      issuedAt: issuedAt ?? this.issuedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lines: lines ?? this.lines,
      adjustments: adjustments ?? this.adjustments,
    );
  }
}
