/// Why this file exists:
/// Use case for updating property details.
library;

import '../../../../core/errors/failure.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class UpdateProperty {
  final PropertyRepository repository;

  UpdateProperty(this.repository);

  Future<void> call(Property property) async {
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

    await repository.updateProperty(updated);
  }
}
