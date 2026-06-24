/// Why the file exists:
/// Use Case for calculating the dynamic outstanding balance of an Invoice.
/// Formula: total_amount - Net Paid, and never stored persistently.
library;

import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/payment_balance_reader.dart';
import '../repositories/invoice_repository.dart';

class CalculateOutstandingBalance {
  final InvoiceRepository _repository;
  final PaymentBalanceReader _paymentBalanceReader;

  CalculateOutstandingBalance(this._repository, this._paymentBalanceReader);

  Future<Money> call(int invoiceId) async {
    final invoice = await _repository.getInvoiceById(invoiceId);
    if (invoice == null) {
      throw const ValidationFailure(
        code: 'INVOICE_NOT_FOUND',
        message: 'الفاتورة المطلوبة غير موجودة في النظام لحساب الرصيد المستحق.',
      );
    }

    final invoiceTotal = invoice.status == InvoiceStatus.draft
        ? invoice.calculatedTotal
        : invoice.totalAmount;

    final netPaid = await _paymentBalanceReader.getNetPaymentsForInvoice(invoiceId);

    final balanceMinor = invoiceTotal.minorUnits - netPaid.minorUnits;
    return Money(balanceMinor < 0 ? 0 : balanceMinor);
  }
}
