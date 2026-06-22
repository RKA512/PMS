/// Why the file exists:
/// Use Case for updating an existing Draft Invoice with business validations.
/// Refused if the invoice is not in Draft state.
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/errors/failure.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class UpdateInvoice {
  final InvoiceRepository _repository;

  UpdateInvoice(this._repository);

  Future<void> call(Invoice invoice, int userId) async {
    if (invoice.id == null) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_MISSING',
        message: 'تعذر التحديث: معرف الفاتورة غير محدد.',
      );
    }

    // Fetch existing first to ensure state guarantees
    final existing = await _repository.getInvoiceById(invoice.id!);
    if (existing == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'فشل التحديث: الفاتورة غير موجودة في النظام.',
      );
    }

    if (existing.status != InvoiceStatus.draft) {
      throw const BusinessRuleFailure(
        code: 'INVOICE_NOT_EDITABLE',
        message: 'تعديل الفاتورة مرفوض: الفواتير الصادرة أو المغلقة غير قابلة للتعديل أو التحديث المباشر.',
      );
    }

    if (invoice.lines.isEmpty) {
      throw const BusinessRuleFailure(
        code: 'EMPTY_INVOICE_NOT_ALLOWED',
        message: 'لا يمكن حفظ الفاتورة: يجب إبقاء بند مالي واحد على الأقل للفاتورة.',
      );
    }

    for (final line in invoice.lines) {
      if (line.quantity <= 0) {
        throw ValidationFailure(
          code: 'INVALID_QUANTITY',
          message: 'يجب أن تكون كمية البند "${line.description}" أكبر من الصفر.',
        );
      }
      if (line.unitPrice.minorUnits < 0) {
        throw ValidationFailure(
          code: 'INVALID_UNIT_PRICE',
          message: 'يجب أن يكون سعر بند "${line.description}" أكبر من أو يساوي الصفر.',
        );
      }
    }

    for (final adj in invoice.adjustments) {
      if (adj.amount.minorUnits == 0) {
        throw ValidationFailure(
          code: 'INVALID_ADJUSTMENT_AMOUNT',
          message: 'فشل التعديل "${adj.reason}": لا يمكن إدخال تعديل مالي بقيمة صفر.',
        );
      }
    }

    await _repository.updateInvoice(invoice, userId);
  }
}
