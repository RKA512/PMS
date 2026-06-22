/// Why the file exists:
/// Use Case for retrieving a booking's specific Invoice.
library;

import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class GetInvoiceByBooking {
  final InvoiceRepository _repository;

  GetInvoiceByBooking(this._repository);

  Future<Invoice?> call(int bookingId) async {
    return await _repository.getInvoiceByBookingId(bookingId);
  }
}
