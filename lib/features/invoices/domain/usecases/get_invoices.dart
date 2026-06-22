/// Why the file exists:
/// Use Case for retrieving all invoices belonging to a specific Account ID.
library;

import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoices {
  final InvoiceRepository _repository;

  GetInvoices(this._repository);

  Future<List<Invoice>> call(int accountId) async {
    return await _repository.getInvoices(accountId);
  }
}
