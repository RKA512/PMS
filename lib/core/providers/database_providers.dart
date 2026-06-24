/// Why this file exists:
/// Riverpod state providers for database services and transaction contracts.
/// Satisfies [Architecture Rule AR-011 (Riverpod management)].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../contracts/transaction_runner.dart';
import '../database/database_helper.dart';
import '../database/sqlite_transaction_runner.dart';

final transactionRunnerProvider = Provider<TransactionRunner>((ref) {
  return SqliteTransactionRunner(DatabaseHelper.instance);
});
