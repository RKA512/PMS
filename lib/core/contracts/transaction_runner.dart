/// Why this file exists:
/// Abstraction for running database operations atomically inside a transaction.
/// Satisfies [Architecture Rule AR-001 (Clean Architecture)] and [Design Decisions DEC-019].
library;

abstract class TransactionRunner {
  /// Runs the given [operation] atomically.
  Future<T> run<T>(Future<T> Function() operation);
}
