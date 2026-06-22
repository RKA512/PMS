/// Why the file exists:
/// Use Case for retrieving a specific invoice by its database ID, conforming to Clean Architecture.
library;

import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceById {
  final InvoiceRepository _repository;

  GetInvoiceById(this._repository);

  Future<Invoice?> call(int id) async {
    return await _repository.getInvoiceById(id);
  }
}
