/// Why this file exists:
/// SQLite-specific implementation of TransactionRunner.
/// Satisfies [Architecture Rule AR-001 (Clean Architecture)], [Design Decisions DEC-019], and [Database Schema Design].
library;

import 'dart:async';
import '../contracts/transaction_runner.dart';
import 'database_helper.dart';

class SqliteTransactionRunner implements TransactionRunner {
  final DatabaseHelper _dbHelper;

  SqliteTransactionRunner(this._dbHelper);

  @override
  Future<T> run<T>(Future<T> Function() operation) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      return await runZoned(
        operation,
        zoneValues: { #sqlite_txn: txn },
      );
    });
  }
}
