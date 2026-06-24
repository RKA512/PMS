/// Why the file exists:
/// Use Case for creating a new Draft Invoice with business rule validations.
/// Implements [Application Flows Flow-12] and validates that an invoice has at least one line,
/// and that quantity > 0, unit price >= 0, and bookingId is set.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoice {
  final InvoiceRepository _repository;
  final AuditLogger _auditService;

  CreateInvoice(this._repository, this._auditService);

  Future<int> call(Invoice invoice, int userId) async {
    // 1. Business & MVP Validation Rules
    if (invoice.bookingId <= 0) {
      throw const ValidationFailure(
        code: 'INVALID_BOOKING_LINK',
        message: 'يجب ربط الفاتورة بحجز صحيح.',
      );
    }

    // Check if an invoice already exists for this booking ID
    final existingInvoice = await _repository.getInvoiceByBookingId(invoice.bookingId);
    if (existingInvoice != null) {
      throw const BusinessRuleFailure(
        code: 'DUPLICATE_BOOKING_INVOICE',
        message: 'تنبيه مالي: يوجد بالفعل فاتورة مرتبطة بهذا الحجز ومن غير المسموح إنشاء فاتورة مكررة لنفس الحجز.',
      );
    }

    if (invoice.lines.isEmpty) {
      throw const BusinessRuleFailure(
        code: 'EMPTY_INVOICE_NOT_ALLOWED',
        message: 'لا يمكن حفظ الفاتورة: يجب إضافة بند مالي واحد على الأقل للفاتورة.',
      );
    }

    for (final line in invoice.lines) {
      if (line.quantity <= 0) {
        throw ValidationFailure(
          code: 'INVALID_QUANTITY',
          message: 'فشل البند "${line.description}": يجب أن تكون الكمية أكبر من الصفر.',
        );
      }
      if (line.unitPrice.minorUnits < 0) {
        throw ValidationFailure(
          code: 'INVALID_UNIT_PRICE',
          message: 'فشل البند "${line.description}": يجب أن يكون سعر الوحدة أكبر من أو يساوي الصفر.',
        );
      }
    }

    for (final adj in invoice.adjustments) {
      if (adj.amount.minorUnits == 0) {
        throw ValidationFailure(
          code: 'INVALID_ADJUSTMENT_AMOUNT',
          message: 'فشل التعديل "${adj.reason}": لا يمكن أن تكون قيمة التعديل صفراً.',
        );
      }
    }

    // Prepare Invoice with final standard values (e.g., generate a fresh uuid if empty)
    final prepared = invoice.copyWith(
      uuid: invoice.uuid.isEmpty ? const Uuid().v4() : invoice.uuid,
    );

    final id = await _repository.createInvoice(prepared, userId);

    // Log audit event
    await _auditService.log(
      userId: userId,
      entityType: 'Invoice',
      entityId: id,
      action: 'Create Invoice',
      description: 'تم إنشاء مسودة فاتورة جديدة برقم ${prepared.invoiceNumber}.',
    );

    return id;
  }
}
