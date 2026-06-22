/// Why this file exists:
/// Use cases for reading and writing property-specific configurations.
library;

import '../entities/property_settings.dart';
import '../repositories/property_repository.dart';

class GetPropertySettings {
  final PropertyRepository repository;

  GetPropertySettings(this.repository);

  Future<List<PropertySettings>> call(int propertyId) async {
    return await repository.getPropertySettings(propertyId);
  }
}

class SavePropertySetting {
  final PropertyRepository repository;

  SavePropertySetting(this.repository);

  Future<void> call({
    required int propertyId,
    required String key,
    required String value,
  }) async {
    await repository.savePropertySetting(propertyId, key, value);
  }
}

class GetPropertySettingValue {
  final PropertyRepository repository;

  GetPropertySettingValue(this.repository);

  Future<String?> call(int propertyId, String key) async {
    return await repository.getPropertySettingValue(propertyId, key);
  }
}
