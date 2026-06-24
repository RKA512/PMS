import 'package:sqflite/sqflite.dart';
import '../common/models/money.dart';
import '../errors/failure.dart';
import 'database_helper.dart';
import '../contracts/payment_balance_reader.dart';

/// Why this file exists:
/// Implements [PaymentBalanceReader] using SQLite.
/// Positioned inside `/core/database/` to decouple the Invoices module
/// from any concrete payments-table SQL queries, conforming to SOLID and Clean Architecture.
class SqlitePaymentBalanceReader implements PaymentBalanceReader {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<Money> getNetPaymentsForInvoice(int invoiceId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> res = await db.rawQuery('''
        SELECT 
          SUM(CASE WHEN payment_type = 'incoming' THEN amount ELSE 0 END) as incoming,
          SUM(CASE WHEN payment_type = 'refund' THEN amount ELSE 0 END) as refund
        FROM payments 
        WHERE invoice_id = ?
      ''', [invoiceId]);

      final incoming = res.first['incoming'] as int? ?? 0;
      final refund = res.first['refund'] as int? ?? 0;
      final netPaid = incoming - refund;

      return Money(netPaid);
    } on DatabaseException catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('no such table: payments') || errorMessage.contains('no such table')) {
        // Safe fallback of zero only if the payments table is not yet created in this phase.
        return const Money(0);
      }
      // Log / rethrow database issues as DatabaseFailure
      throw DatabaseFailure(
        code: 'PAYMENT_BALANCE_ERR',
        message: 'حدث خطأ في قاعدة البيانات أثناء قراءة رصيد المدفوعات: ${e.toString()}',
      );
    } catch (e) {
      throw DatabaseFailure(
        code: 'PAYMENT_BALANCE_UNEXPECTED',
        message: 'حدث خطأ غير متوقع أثناء قراءة رصيد المدفوعات: $e',
      );
    }
  }
}
