/// Why the file exists:
/// Use Case for fetching all bookings that do not have an invoice generated yet.
/// Follows Clean Architecture design and ensures UI does not access database directly.
library;

import '../repositories/invoice_repository.dart';

class GetUninvoicedBookings {
  final InvoiceRepository _repository;

  GetUninvoicedBookings(this._repository);

  Future<List<Map<String, dynamic>>> call() async {
    return await _repository.getUninvoicedBookings();
  }
}
