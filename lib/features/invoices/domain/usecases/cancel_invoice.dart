/// Why the file exists:
/// Use Case for cancelling an existing Invoice (unless it is already fully paid).
/// Implements [Application Flows Flow-14] and maintains full audit records of cancel transitions.
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/invoice_repository.dart';

class CancelInvoice {
  final InvoiceRepository _repository;
  final AuditLogger _auditService;

  CancelInvoice(this._repository, this._auditService);

  Future<void> call(int invoiceId, int userId) async {
    final invoice = await _repository.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة غير موجودة.',
      );
    }

    if (invoice.status == InvoiceStatus.paid) {
      throw const BusinessRuleFailure(
        code: 'CANCEL_PAID_REJECTED',
        message: 'إلغاء الفاتورة مرفوض: لا يمكن إلغاء الفواتير التي سُددت بالكامل (Paid invoices cannot be cancelled).',
      );
    }

    if (invoice.status == InvoiceStatus.cancelled) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CANCELLED',
        message: 'الفاتورة ملغاة بالفعل في النظام.',
      );
    }

    await _repository.cancelInvoice(invoiceId, userId);

    await _auditService.log(
      userId: userId,
      entityType: 'Invoice',
      entityId: invoiceId,
      action: 'Cancel Invoice',
      description: 'تم إلغاء الفاتورة بالكامل وتغيير حالتها إلى ملغاة.',
    );
  }
}
