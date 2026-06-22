/// Why the file exists:
/// Represents audit log model parameters. 
/// Implements [Audit Policy AP-100] and [Domain Model AuditLog].
/// Ensures old values and new values are tracked in raw JSON.
library;

class AuditEntry {
  final int? id;
  final String uuid;
  final int? propertyId;
  final int userId;
  final String entityType;
  final int entityId;
  final String action;
  final String description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final DateTime createdAt;

  const AuditEntry({
    this.id,
    required this.uuid,
    this.propertyId,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.description,
    this.oldValues,
    this.newValues,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'property_id': propertyId,
      'user_id': userId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'description': description,
      'old_values': oldValues != null ? oldValues.toString() : null, // normally json stringified
      'new_values': newValues != null ? newValues.toString() : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      propertyId: map['property_id'] as int?,
      userId: map['user_id'] as int,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as int,
      action: map['action'] as String,
      description: map['description'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
