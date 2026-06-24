/// Why the file exists:
/// Use Case for adding a single line to a Draft Invoice.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/invoice_line.dart';
import '../repositories/invoice_repository.dart';

class AddInvoiceLine {
  final InvoiceRepository _repository;
  final AuditLogger _auditService;

  AddInvoiceLine(this._repository, this._auditService);

  Future<void> call(InvoiceLine line, int userId) async {
    if (line.invoiceId == null || line.invoiceId! <= 0) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_REQUIRED',
        message: 'معرف الفاتورة مطلوب لإضافة بند جديد.',
      );
    }

    final invoice = await _repository.getInvoiceById(line.invoiceId!);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة المستهدفة غير موجودة في النظام.',
      );
    }

    if (invoice.status != InvoiceStatus.draft) {
      throw const BusinessRuleFailure(
        code: 'INVOICE_NOT_EDITABLE',
        message: 'تعديل الفاتورة مرفوض: لا يمكن إضافة بنود إلا للفواتير التي في حالة مسودة.',
      );
    }

    if (line.quantity <= 0) {
      throw const ValidationFailure(
        code: 'INVALID_QUANTITY',
        message: 'يجب أن تكون كمية البند المضاف أكبر من الصفر.',
      );
    }
    if (line.unitPrice.minorUnits < 0) {
      throw const ValidationFailure(
        code: 'INVALID_UNIT_PRICE',
        message: 'يجب أن يكون سعر الوحدة للبلد المضاف أكبر من أو يساوي الصفر.',
      );
    }

    final prepared = InvoiceLine.create(
      description: line.description,
      quantity: line.quantity,
      unitPrice: line.unitPrice,
      invoiceId: line.invoiceId,
    );

    await _repository.addInvoiceLine(prepared, userId);

    await _auditService.log(
      userId: userId,
      entityType: 'Invoice',
      entityId: prepared.invoiceId!,
      action: 'Add Line',
      description: 'تمت إضافة بند جديد: ${prepared.description} بقيمة ${prepared.lineTotal}.',
    );
  }
}
