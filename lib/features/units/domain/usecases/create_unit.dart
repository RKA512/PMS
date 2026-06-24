/// Why this file exists:
/// Use case for creating a new unit under a property.
/// Asserts name, unit number, and positive capacity constraints.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/common/enums/unit_status.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/unit_model.dart';
import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

class CreateUnit {
  final UnitRepository repository;
  final AuditLogger auditService;
  final _uuid = const Uuid();

  CreateUnit(this.repository, this.auditService);

  Future<int> call({
    required int propertyId,
    required int unitTypeId,
    required String name,
    required String unitNumber,
    int? floorNumber,
    required int capacity,
    String? notes,
    required int userId,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'UNIT_NAME_EMPTY',
        message: 'اسم الوحدة لا يمكن أن يكون فارغاً (Unit name cannot be empty)',
      );
    }
    if (unitNumber.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'UNIT_NUMBER_EMPTY',
        message: 'رقم الوحدة لا يمكن أن يكون فارغاً (Unit number cannot be empty)',
      );
    }
    if (capacity <= 0) {
      throw const ValidationFailure(
        code: 'UNIT_CAPACITY_INVALID',
        message: 'السعة الاستيعابية يجب أن تكون أكبر من صفر (Capacity must be greater than zero)',
      );
    }

    final now = DateTime.now();
    final unit = Unit(
      uuid: _uuid.v4(),
      propertyId: propertyId,
      unitTypeId: unitTypeId,
      name: name.trim(),
      unitNumber: unitNumber.trim(),
      floorNumber: floorNumber,
      capacity: capacity,
      status: UnitStatus.available,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final id = await repository.createUnit(unit);

    // Log Audit Event
    await auditService.log(
      propertyId: unit.propertyId,
      userId: userId,
      entityType: 'Unit',
      entityId: id,
      action: 'Create Unit',
      description: 'Created unit ${unit.name} (Room: ${unit.unitNumber})',
      newValues: UnitModel.toMap(
        unit.copyWith(id: id),
      ),
    );

    return id;
  }
}
