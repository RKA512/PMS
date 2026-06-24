/// Why this file exists:
/// Use case for restoring (unarchiving) units safely.
library;

import '../../../../core/common/enums/unit_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/unit_model.dart';
import '../repositories/unit_repository.dart';

class UnarchiveUnit {
  final UnitRepository repository;
  final AuditLogger auditService;

  UnarchiveUnit(this.repository, this.auditService);

  Future<void> call({required int id, required int userId}) async {
    final unit = await repository.getUnitById(id);
    if (unit == null) return;
    final oldMap = UnitModel.toMap(unit);

    await repository.unarchiveUnit(id);

    final nowString = DateTime.now().toIso8601String();
    await auditService.log(
      propertyId: unit.propertyId,
      userId: userId,
      entityType: 'Unit',
      entityId: id,
      action: 'Unarchive Unit',
      description: 'Restored unit ${unit.name} (Room: ${unit.unitNumber})',
      oldValues: oldMap,
      newValues: {
        'deleted_at': null,
        'status': UnitStatus.available.toJson(),
        'updated_at': nowString,
      },
    );
  }
}
