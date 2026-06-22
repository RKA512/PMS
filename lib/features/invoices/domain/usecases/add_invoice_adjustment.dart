/// Why the file exists:
/// Use Case for adding a financial adjustment to a Draft Invoice.
library;

import '../../../../core/errors/failure.dart';
import '../entities/invoice_adjustment.dart';
import '../repositories/invoice_repository.dart';

class AddInvoiceAdjustment {
  final InvoiceRepository _repository;

  AddInvoiceAdjustment(this._repository);

  Future<void> call(InvoiceAdjustment adjustment, int userId) async {
    if (adjustment.invoiceId == null || adjustment.invoiceId! <= 0) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_REQUIRED',
        message: 'معرف الفاتورة مطلوب لإجراء التعديل المالي.',
      );
    }
    if (adjustment.amount.minorUnits == 0) {
      throw const ValidationFailure(
        code: 'INVALID_ADJUSTMENT',
        message: 'يجب أن يكون مبلغ التعديل المالي رقماً غير مساوٍ للصفر.',
      );
    }
    await _repository.addInvoiceAdjustment(adjustment, userId);
  }
}
