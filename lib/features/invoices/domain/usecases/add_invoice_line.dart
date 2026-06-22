/// Why the file exists:
/// Use Case for adding a single line to a Draft Invoice.
library;

import '../../../../core/errors/failure.dart';
import '../entities/invoice_line.dart';
import '../repositories/invoice_repository.dart';

class AddInvoiceLine {
  final InvoiceRepository _repository;

  AddInvoiceLine(this._repository);

  Future<void> call(InvoiceLine line, int userId) async {
    if (line.invoiceId == null || line.invoiceId! <= 0) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_REQUIRED',
        message: 'معرف الفاتورة مطلوب لإضافة بند جديد.',
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
  }
}
