/// Why this file exists:
/// Use case for soft deleting (archiving) units safely.
library;

import '../../../../core/common/enums/unit_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/unit_model.dart';
import '../repositories/unit_repository.dart';

class ArchiveUnit {
  final UnitRepository repository;
  final AuditLogger auditService;

  ArchiveUnit(this.repository, this.auditService);

  Future<void> call({required int id, required int userId}) async {
    final unit = await repository.getUnitById(id);
    if (unit == null) return;
    final oldMap = UnitModel.toMap(unit);

    await repository.archiveUnit(id);

    final nowString = DateTime.now().toIso8601String();
    await auditService.log(
      propertyId: unit.propertyId,
      userId: userId,
      entityType: 'Unit',
      entityId: id,
      action: 'Archive Unit',
      description: 'Archived unit ${unit.name} (Room: ${unit.unitNumber})',
      oldValues: oldMap,
      newValues: {
        'deleted_at': nowString,
        'status': UnitStatus.archived.toJson(),
        'updated_at': nowString,
      },
    );
  }
}
