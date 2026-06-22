/// Why this file exists:
/// Standard Domain Entity for Unit.
/// Satisfies [Domain Model Unit] and binds properties with strong typing.
library;

import '../../../../core/common/enums/unit_status.dart';

class Unit {
  final int? id;
  final String uuid;
  final int propertyId;
  final int unitTypeId;
  final String name;
  final String unitNumber;
  final int? floorNumber;
  final int capacity;
  final UnitStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Unit({
    this.id,
    required this.uuid,
    required this.propertyId,
    required this.unitTypeId,
    required this.name,
    required this.unitNumber,
    this.floorNumber,
    required this.capacity,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Unit copyWith({
    int? id,
    String? uuid,
    int? propertyId,
    int? unitTypeId,
    String? name,
    String? unitNumber,
    int? floorNumber,
    int? capacity,
    UnitStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Unit(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      propertyId: propertyId ?? this.propertyId,
      unitTypeId: unitTypeId ?? this.unitTypeId,
      name: name ?? this.name,
      unitNumber: unitNumber ?? this.unitNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
