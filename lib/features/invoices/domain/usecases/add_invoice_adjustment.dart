/// Why the file exists:
/// Use Case for adding a financial adjustment to a Draft Invoice.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/invoice_adjustment.dart';
import '../repositories/invoice_repository.dart';

class AddInvoiceAdjustment {
  final InvoiceRepository _repository;
  final AuditLogger _auditService;

  AddInvoiceAdjustment(this._repository, this._auditService);

  Future<void> call(InvoiceAdjustment adjustment, int userId) async {
    if (adjustment.invoiceId == null || adjustment.invoiceId! <= 0) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_REQUIRED',
        message: 'معرف الفاتورة مطلوب لإجراء التعديل المالي.',
      );
    }

    final invoice = await _repository.getInvoiceById(adjustment.invoiceId!);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة المستهدفة غير موجودة في النظام.',
      );
    }

    if (invoice.status != InvoiceStatus.draft) {
      throw const BusinessRuleFailure(
        code: 'INVOICE_NOT_EDITABLE',
        message: 'تعديل الفاتورة مرفوض: لا يمكن إضافة تعديلات إلا في حالة المسودة.',
      );
    }

    if (adjustment.amount.minorUnits == 0) {
      throw const ValidationFailure(
        code: 'INVALID_ADJUSTMENT',
        message: 'يجب أن يكون مبلغ التعديل المالي رقماً غير مساوٍ للصفر.',
      );
    }
    await _repository.addInvoiceAdjustment(adjustment, userId);

    await _auditService.log(
      userId: userId,
      entityType: 'Invoice',
      entityId: adjustment.invoiceId!,
      action: 'Add Adjustment',
      description: 'تمت إضافة تعديل (${adjustment.adjustmentType.displayName}) بقيمة ${adjustment.amount} وبسبب: ${adjustment.reason}.',
    );
  }
}
