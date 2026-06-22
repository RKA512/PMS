/// Why this file exists:
/// Model representing Unit mapping to and from SQLite columns.
/// Satisfies [Model Rules AR-500 / AR-501] and isolates SQL mapping.
library;

import '../../../../core/common/enums/unit_status.dart';
import '../../domain/entities/unit.dart';

class UnitModel {
  static Map<String, dynamic> toMap(Unit unit) {
    return {
      if (unit.id != null) 'id': unit.id,
      'uuid': unit.uuid,
      'property_id': unit.propertyId,
      'unit_type_id': unit.unitTypeId,
      'name': unit.name,
      'unit_number': unit.unitNumber,
      'floor_number': unit.floorNumber,
      'capacity': unit.capacity,
      'status': unit.status.toJson(),
      'notes': unit.notes,
      'created_at': unit.createdAt.toIso8601String(),
      'updated_at': unit.updatedAt.toIso8601String(),
      'deleted_at': unit.deletedAt?.toIso8601String(),
    };
  }

  static Unit fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      propertyId: map['property_id'] as int,
      unitTypeId: map['unit_type_id'] as int,
      name: map['name'] as String,
      unitNumber: map['unit_number'] as String,
      floorNumber: map['floor_number'] as int?,
      capacity: map['capacity'] as int,
      status: UnitStatus.fromJson(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
