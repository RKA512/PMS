/// Why the file exists:
/// Riverpod state providers and StateNotifiers for Invoice Management.
/// Implements [Architecture Rule AR-011] for managing state and flows securely.
library;

import '../../../../core/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/usecases/create_invoice.dart';
import '../../domain/usecases/update_invoice.dart';
import '../../domain/usecases/add_invoice_line.dart';
import '../../domain/usecases/remove_invoice_line.dart';
import '../../domain/usecases/add_invoice_adjustment.dart';
import '../../domain/usecases/issue_invoice.dart';
import '../../domain/usecases/cancel_invoice.dart';
import '../../domain/usecases/get_invoice_by_booking.dart';
import '../../domain/usecases/get_invoices.dart';
import '../../domain/usecases/calculate_outstanding_balance.dart';
import '../../domain/usecases/get_uninvoiced_bookings.dart';
import '../../domain/usecases/get_invoice_by_id.dart';

// Repository Provider
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl();
});

// Use Case Providers
final createInvoiceUseCaseProvider = Provider<CreateInvoice>((ref) {
  return CreateInvoice(ref.watch(invoiceRepositoryProvider));
});

final updateInvoiceUseCaseProvider = Provider<UpdateInvoice>((ref) {
  return UpdateInvoice(ref.watch(invoiceRepositoryProvider));
});

final addInvoiceLineUseCaseProvider = Provider<AddInvoiceLine>((ref) {
  return AddInvoiceLine(ref.watch(invoiceRepositoryProvider));
});

final removeInvoiceLineUseCaseProvider = Provider<RemoveInvoiceLine>((ref) {
  return RemoveInvoiceLine(ref.watch(invoiceRepositoryProvider));
});

final addInvoiceAdjustmentUseCaseProvider = Provider<AddInvoiceAdjustment>((ref) {
  return AddInvoiceAdjustment(ref.watch(invoiceRepositoryProvider));
});

final issueInvoiceUseCaseProvider = Provider<IssueInvoice>((ref) {
  return IssueInvoice(ref.watch(invoiceRepositoryProvider));
});

final cancelInvoiceUseCaseProvider = Provider<CancelInvoice>((ref) {
  return CancelInvoice(ref.watch(invoiceRepositoryProvider));
});

final getInvoiceByBookingUseCaseProvider = Provider<GetInvoiceByBooking>((ref) {
  return GetInvoiceByBooking(ref.watch(invoiceRepositoryProvider));
});

final getInvoicesUseCaseProvider = Provider<GetInvoices>((ref) {
  return GetInvoices(ref.watch(invoiceRepositoryProvider));
});

final calculateOutstandingBalanceUseCaseProvider = Provider<CalculateOutstandingBalance>((ref) {
  return CalculateOutstandingBalance(ref.watch(invoiceRepositoryProvider));
});

final getUninvoicedBookingsUseCaseProvider = Provider<GetUninvoicedBookings>((ref) {
  return GetUninvoicedBookings(ref.watch(invoiceRepositoryProvider));
});

final getInvoiceByIdUseCaseProvider = Provider<GetInvoiceById>((ref) {
  return GetInvoiceById(ref.watch(invoiceRepositoryProvider));
});

// Search & filter providers
final invoiceSearchQueryProvider = StateProvider<String>((ref) => '');

// Notifier for Invoices list
class InvoicesListNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final GetInvoices _getInvoices;

  InvoicesListNotifier(this._getInvoices) : super(const AsyncValue.loading());

  void setEmpty() {
    state = const AsyncValue.data([]);
  }

  Future<void> fetchInvoices(int accountId, {String filterQuery = ''}) async {
    state = const AsyncValue.loading();
    try {
      final list = await _getInvoices(accountId);
      
      // Perform localized client searching for visual responsiveness
      if (filterQuery.trim().isNotEmpty) {
        final query = filterQuery.trim().toLowerCase();
        final filtered = list.where((inv) {
          return inv.invoiceNumber.toLowerCase().contains(query) ||
                 inv.status.name.toLowerCase().contains(query);
        }).toList();
        state = AsyncValue.data(filtered);
      } else {
        state = AsyncValue.data(list);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final invoicesListProvider = StateNotifierProvider<InvoicesListNotifier, AsyncValue<List<Invoice>>>((ref) {
  final getInvs = ref.watch(getInvoicesUseCaseProvider);
  final accountId = ref.watch(activeAccountIdProvider);
  final query = ref.watch(invoiceSearchQueryProvider);

  final notifier = InvoicesListNotifier(getInvs);

  if (accountId == null) {
    notifier.setEmpty();
  } else {
    // Fetch reactively on active session context
    Future.microtask(() => notifier.fetchInvoices(accountId, filterQuery: query));
  }

  return notifier;
});

// Provider to watch specific booking's invoice with reload/refresh support
final bookingInvoiceProvider = FutureProvider.family<Invoice?, int>((ref, bookingId) async {
  final getByBooking = ref.watch(getInvoiceByBookingUseCaseProvider);
  return await getByBooking(bookingId);
});

// Dynamic outstanding balance provider for a specific invoice
final invoiceOutstandingBalanceProvider = FutureProvider.family<double, int>((ref, invoiceId) async {
  final calcBalance = ref.watch(calculateOutstandingBalanceUseCaseProvider);
  final m = await calcBalance(invoiceId);
  return m.asDouble;
});
