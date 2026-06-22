/// Why the file exists:
/// Use Case for issuing a Draft Invoice to turn it read-only, saving and freezing total_amount.
/// Implements [Application Flows Flow-13] and is a key accounting milestone.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../repositories/invoice_repository.dart';

class IssueInvoice {
  final InvoiceRepository _repository;

  IssueInvoice(this._repository);

  Future<void> call(int invoiceId, int userId) async {
    final invoice = await _repository.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة غير موجودة في النظام.',
      );
    }

    if (invoice.status != InvoiceStatus.draft) {
      throw const BusinessRuleFailure(
        code: 'INVOICE_NOT_DRAFT',
        message: 'إصدار الفاتورة مرفوض: الفاتورة بالفعل صادرة أو ملغاة.',
      );
    }

    if (invoice.lines.isEmpty) {
      throw const BusinessRuleFailure(
        code: 'EMPTY_INVOICE',
        message: 'إصدار الفاتورة مرفوض: يجب أن تحتوي الفاتورة على بند مالي واحد على الأقل قبل إصدارها.',
      );
    }

    // Freeze total amount using dynamic calculation of subtotal + adjustments
    final frozenTotal = invoice.calculatedTotal;

    await _repository.issueInvoice(invoiceId, frozenTotal, userId);
  }
}
