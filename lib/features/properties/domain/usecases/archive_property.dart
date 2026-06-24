/// Why this file exists:
/// Use case for soft deleting (archiving) properties safely.
library;

import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/property_model.dart';
import '../repositories/property_repository.dart';

class ArchiveProperty {
  final PropertyRepository repository;
  final AuditLogger auditService;

  ArchiveProperty(this.repository, this.auditService);

  Future<void> call({required int id, required int userId}) async {
    final property = await repository.getPropertyById(id);
    if (property == null) return;
    final oldMap = PropertyModel.toMap(property);

    await repository.archiveProperty(id);

    final nowString = DateTime.now().toIso8601String();
    await auditService.log(
      propertyId: id,
      userId: userId,
      entityType: 'Property',
      entityId: id,
      action: 'Archive Property',
      description: 'Archived property: ${property.name}',
      oldValues: oldMap,
      newValues: {
        'deleted_at': nowString,
        'status': 'Archived',
        'updated_at': nowString,
      },
    );
  }
}
