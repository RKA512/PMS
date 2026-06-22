/// Why the file exists:
/// Use Case for calculating the dynamic outstanding balance of an Invoice.
/// Formula: total_amount - Net Paid, and never stored persistently.
library;

import '../../../../core/common/models/money.dart';
import '../repositories/invoice_repository.dart';

class CalculateOutstandingBalance {
  final InvoiceRepository _repository;

  CalculateOutstandingBalance(this._repository);

  Future<Money> call(int invoiceId) async {
    return await _repository.calculateOutstandingBalance(invoiceId);
  }
}
