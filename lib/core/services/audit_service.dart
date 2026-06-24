/// Why the file exists:
/// Centralized service for recording system, operational, and financial audit logs database-side.
/// Implements [Audit Policy (AP-001, AP-100)] and [Design Decisions DD-023 (Audit logs immutable)].
/// Bypassing, deleting, or updating audit logs is strictly FORBIDDEN.
library;

import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../common/models/audit_entry.dart';
import '../contracts/audit_logger.dart';

class AuditService implements AuditLogger {
  static final AuditService instance = AuditService._init();
  final _uuid = const Uuid();

  AuditService._init();

  /// Log a system event securely.
  /// Implements AP-100.
  Future<int> log({
    int? propertyId,
    required int userId,
    required String entityType,
    required int entityId,
    required String action,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final uuidString = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final values = {
      'uuid': uuidString,
      'property_id': propertyId,
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'description': description,
      'old_values': oldValues != null ? jsonEncode(oldValues) : null,
      'new_values': newValues != null ? jsonEncode(newValues) : null,
      'created_at': now,
    };

    return await db.insert('audit_logs', values);
  }

  /// Get Paginated and filtered logs.
  /// Implements AP-1500.
  Future<List<AuditEntry>> queryLogs({
    int? userId,
    int? propertyId,
    String? entityType,
    int? entityId,
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }
    if (propertyId != null) {
      whereClauses.add('property_id = ?');
      whereArgs.add(propertyId);
    }
    if (entityType != null) {
      whereClauses.add('entity_type = ?');
      whereArgs.add(entityType);
    }
    if (entityId != null) {
      whereClauses.add('entity_id = ?');
      whereArgs.add(entityId);
    }
    if (action != null) {
      whereClauses.add('action = ?');
      whereArgs.add(action);
    }
    if (startDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereString = whereClauses.isNotEmpty 
        ? 'WHERE ${whereClauses.join(' AND ')}' 
        : '';

    final query = '''
      SELECT * FROM audit_logs
      $whereString
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    ''';

    final args = [...whereArgs, limit, offset];
    final maps = await db.rawQuery(query, args);

    return maps.map((map) {
      Map<String, dynamic>? decodedOld;
      Map<String, dynamic>? decodedNew;
      try {
        if (map['old_values'] != null) {
          decodedOld = jsonDecode(map['old_values'] as String) as Map<String, dynamic>;
        }
        if (map['new_values'] != null) {
          decodedNew = jsonDecode(map['new_values'] as String) as Map<String, dynamic>;
        }
      } catch (_) {}

      return AuditEntry(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        propertyId: map['property_id'] as int?,
        userId: map['user_id'] as int,
        entityType: map['entity_type'] as String,
        entityId: map['entity_id'] as int,
        action: map['action'] as String,
        description: map['description'] as String,
        oldValues: decodedOld,
        newValues: decodedNew,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();
  }
}

// Global Riverpod provider for AuditService
final auditServiceProvider = Provider<AuditLogger>((ref) {
  return AuditService.instance;
});
