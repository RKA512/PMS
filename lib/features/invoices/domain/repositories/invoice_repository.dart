/// Why the file exists:
/// Abstract repository contract defining all operations for Invoice Management.
/// Implements [Domain Model Invoice Repository Contract] and architecture boundary rule [AR-011].
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../entities/invoice.dart';
import '../entities/invoice_adjustment.dart';
import '../entities/invoice_line.dart';

abstract class InvoiceRepository {
  /// Fetches an Invoice by its ID.
  Future<Invoice?> getInvoiceById(int id);

  /// Fetches an Invoice by its associated Booking ID.
  Future<Invoice?> getInvoiceByBookingId(int bookingId);

  /// Fetches all Invoices under a specific account.
  Future<List<Invoice>> getInvoices(int accountId);

  /// Creates a new Invoice in the [InvoiceStatus.draft] state.
  Future<int> createInvoice(Invoice invoice, int userId);

  /// Updates an existing Invoice (only allowed if status = Draft).
  Future<void> updateInvoice(Invoice invoice, int userId);

  /// Adds a line item to a Draft Invoice.
  Future<void> addInvoiceLine(InvoiceLine line, int userId);

  /// Removes a line item from a Draft Invoice.
  Future<void> removeInvoiceLine(int lineId, int userId);

  /// Adds an adjustment (discount, manual, correction) to a Draft Invoice.
  Future<void> addInvoiceAdjustment(InvoiceAdjustment adjustment, int userId);

  /// Issues the Invoice, transitioning from Draft to Issued and freezing the total amount.
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId);

  /// Cancels the Invoice, transitioning its state to Cancelled (only if not Paid).
  Future<void> cancelInvoice(int invoiceId, int userId);

  /// Fetches the Invoice ID associated with a given line item.
  Future<int?> getInvoiceIdByLineId(int lineId);

  /// Fetches bookings that do not have an invoice yet.
  Future<List<Map<String, dynamic>>> getUninvoicedBookings();
}
