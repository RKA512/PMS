/// Why this file exists:
/// Use case for editing unit profiles.
library;

import '../../../../core/errors/failure.dart';
import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

class UpdateUnit {
  final UnitRepository repository;

  UpdateUnit(this.repository);

  Future<void> call(Unit unit) async {
    if (unit.id == null) {
      throw const ValidationFailure(
        code: 'UNIT_ID_MISSING',
        message: 'معرّف الوحدة مفقود (Unit ID is missing)',
      );
    }
    if (unit.name.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'UNIT_NAME_EMPTY',
        message: 'اسم الوحدة لا يمكن أن يكون فارغاً (Unit name cannot be empty)',
      );
    }
    if (unit.unitNumber.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'UNIT_NUMBER_EMPTY',
        message: 'رقم الوحدة لا يمكن أن يكون فارغاً (Unit number cannot be empty)',
      );
    }
    if (unit.capacity <= 0) {
      throw const ValidationFailure(
        code: 'UNIT_CAPACITY_INVALID',
        message: 'السعة الاستيعابية يجب أن تكون أكبر من صفر (Capacity must be greater than zero)',
      );
    }

    final updated = unit.copyWith(
      name: unit.name.trim(),
      unitNumber: unit.unitNumber.trim(),
      notes: unit.notes?.trim(),
      updatedAt: DateTime.now(),
    );

    await repository.updateUnit(updated);
  }
}
