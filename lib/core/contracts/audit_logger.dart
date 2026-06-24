/// Why this file exists:
/// Interface/contract for audit logging to decouple components from a concrete database-backed service.
/// Satisfies [Architecture Rule AR-001 (Clean Architecture)] and [Design Decisions DD-023].
library;

abstract class AuditLogger {
  /// Log a system or operational event securely.
  Future<int> log({
    int? propertyId,
    required int userId,
    required String entityType,
    required int entityId,
    required String action,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  });
}
