/// Why the file exists:
/// Riverpod state providers and StateNotifiers for Invoice Management.
/// Implements [Architecture Rule AR-011] for managing state and flows securely.
library;

import 'dart:async';
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../../core/services/audit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../../../core/contracts/payment_balance_reader.dart';
import '../../../../core/database/sqlite_payment_balance_reader.dart';
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

// Payment Balance Reader Provider (Decoupling boundary)
final paymentBalanceReaderProvider = Provider<PaymentBalanceReader>((ref) {
  return SqlitePaymentBalanceReader();
});

// Repository Provider
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepositoryImpl();
});

// Use Case Providers
final createInvoiceUseCaseProvider = Provider<CreateInvoice>((ref) {
  return CreateInvoice(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final updateInvoiceUseCaseProvider = Provider<UpdateInvoice>((ref) {
  return UpdateInvoice(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final addInvoiceLineUseCaseProvider = Provider<AddInvoiceLine>((ref) {
  return AddInvoiceLine(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final removeInvoiceLineUseCaseProvider = Provider<RemoveInvoiceLine>((ref) {
  return RemoveInvoiceLine(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final addInvoiceAdjustmentUseCaseProvider = Provider<AddInvoiceAdjustment>((ref) {
  return AddInvoiceAdjustment(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final issueInvoiceUseCaseProvider = Provider<IssueInvoice>((ref) {
  return IssueInvoice(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final cancelInvoiceUseCaseProvider = Provider<CancelInvoice>((ref) {
  return CancelInvoice(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final getInvoiceByBookingUseCaseProvider = Provider<GetInvoiceByBooking>((ref) {
  return GetInvoiceByBooking(ref.watch(invoiceRepositoryProvider));
});

final getInvoicesUseCaseProvider = Provider<GetInvoices>((ref) {
  return GetInvoices(ref.watch(invoiceRepositoryProvider));
});

final calculateOutstandingBalanceUseCaseProvider = Provider<CalculateOutstandingBalance>((ref) {
  return CalculateOutstandingBalance(
    ref.watch(invoiceRepositoryProvider),
    ref.watch(paymentBalanceReaderProvider),
  );
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
class InvoicesListNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  FutureOr<List<Invoice>> build() async {
    final accountId = ref.watch(activeAccountIdProvider);
    if (accountId == null) return const [];

    final getInvs = ref.watch(getInvoicesUseCaseProvider);
    final query = ref.watch(invoiceSearchQueryProvider);

    final list = await getInvs(accountId);

    if (query.trim().isNotEmpty) {
      final lowercaseQuery = query.trim().toLowerCase();
      return list.where((inv) {
        return inv.invoiceNumber.toLowerCase().contains(lowercaseQuery) ||
               inv.status.name.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    return list;
  }

  Future<void> fetchInvoices(int accountId, {String filterQuery = ''}) async {
    state = const AsyncValue.loading();
    try {
      final getInvs = ref.read(getInvoicesUseCaseProvider);
      final query = filterQuery.isNotEmpty ? filterQuery : ref.read(invoiceSearchQueryProvider);
      final list = await getInvs(accountId);
      
      if (query.trim().isNotEmpty) {
        final lowercaseQuery = query.trim().toLowerCase();
        state = AsyncValue.data(list.where((inv) {
          return inv.invoiceNumber.toLowerCase().contains(lowercaseQuery) ||
                 inv.status.name.toLowerCase().contains(lowercaseQuery);
        }).toList());
      } else {
        state = AsyncValue.data(list);
      }
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final invoicesListProvider = AsyncNotifierProvider<InvoicesListNotifier, List<Invoice>>(() {
  return InvoicesListNotifier();
});

// Provider to watch specific booking's invoice with reload/refresh support
final bookingInvoiceProvider = FutureProvider.family<Invoice?, int>((ref, bookingId) async {
  final getByBooking = ref.watch(getInvoiceByBookingUseCaseProvider);
  return await getByBooking(bookingId);
});

// Dynamic outstanding balance provider for a specific invoice
final invoiceOutstandingBalanceProvider = FutureProvider.family<Money, int>((ref, invoiceId) async {
  final calcBalance = ref.watch(calculateOutstandingBalanceUseCaseProvider);
  return await calcBalance(invoiceId);
});
