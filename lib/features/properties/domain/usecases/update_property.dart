/// Why this file exists:
/// Use case for updating property details.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/property_model.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class UpdateProperty {
  final PropertyRepository repository;
  final AuditLogger auditService;

  UpdateProperty(this.repository, this.auditService);

  Future<void> call({required Property property, required int userId}) async {
    if (property.id == null) {
      throw const ValidationFailure(
        code: 'PROPERTY_ID_MISSING',
        message: 'معرّف العقار مفقود (Property ID is missing)',
      );
    }
    if (property.name.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'PROPERTY_NAME_EMPTY',
        message: 'اسم العقار لا يمكن أن يكون فارغاً (Property name cannot be empty)',
      );
    }

    final updated = property.copyWith(
      name: property.name.trim(),
      address: property.address?.trim(),
      city: property.city?.trim(),
      country: property.country?.trim(),
      phone: property.phone?.trim(),
      email: property.email?.trim(),
      currencyCode: property.currencyCode.trim().toUpperCase(),
      updatedAt: DateTime.now(),
    );

    final oldProperty = await repository.getPropertyById(updated.id!);
    final oldMap = oldProperty != null ? PropertyModel.toMap(oldProperty) : null;

    await repository.updateProperty(updated);

    // Log Audit Event
    await auditService.log(
      propertyId: updated.id!,
      userId: userId,
      entityType: 'Property',
      entityId: updated.id!,
      action: 'Update Property',
      description: 'Updated property: ${updated.name}',
      oldValues: oldMap,
      newValues: PropertyModel.toMap(updated),
    );
  }
}
