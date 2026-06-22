/// Why the file exists:
/// Use Case for removing a single line from a Draft Invoice.
library;

import '../repositories/invoice_repository.dart';

class RemoveInvoiceLine {
  final InvoiceRepository _repository;

  RemoveInvoiceLine(this._repository);

  Future<void> call(int lineId, int userId) async {
    await _repository.removeInvoiceLine(lineId, userId);
  }
}
