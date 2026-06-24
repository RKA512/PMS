import '../common/models/money.dart';

/// Why this file exists:
/// Implements a cross-module decoupling port under core contracts.
/// Defines an abstraction boundary for reading net payments of an invoice,
/// satisfying the SOLID principles and ensuring feature isolation.
abstract class PaymentBalanceReader {
  /// Fetches the net paid amount (incoming payments minus refunds) for a given invoice.
  Future<Money> getNetPaymentsForInvoice(int invoiceId);
}
