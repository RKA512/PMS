/// Why the file exists:
/// Use Case for removing a single line from a Draft Invoice.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/invoice_repository.dart';

class RemoveInvoiceLine {
  final InvoiceRepository _repository;
  final AuditLogger _auditService;

  RemoveInvoiceLine(this._repository, this._auditService);

  Future<void> call(int lineId, int userId) async {
    final invoiceId = await _repository.getInvoiceIdByLineId(lineId);
    if (invoiceId == null) {
      throw const ValidationFailure(
        code: 'LINE_NOT_FOUND',
        message: 'بند الفاتورة غير موجود في النظام.',
      );
    }

    final invoice = await _repository.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة المرتبطة بالبند غير موجودة.',
      );
    }

    if (invoice.status != InvoiceStatus.draft) {
      throw const BusinessRuleFailure(
        code: 'INVOICE_NOT_EDITABLE',
        message: 'تعديل الفاتورة مرفوض: لا يمكن حذف البنود لغير الفاتورة المسودة.',
      );
    }

    final line = invoice.lines.cast<dynamic>().firstWhere(
      (l) => l.id == lineId,
      orElse: () => null,
    );
    final description = line != null ? line.description as String : '';

    await _repository.removeInvoiceLine(lineId, userId);

    await _auditService.log(
      userId: userId,
      entityType: 'Invoice',
      entityId: invoiceId,
      action: 'Remove Line',
      description: 'تم حذف البند "$description" من مسودة الفاتورة.',
    );
  }
}
