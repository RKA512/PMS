/// Why this file exists:
/// Abstract repository contract for all Property, Property Settings and Property Type operations.
/// Follows [Architecture Rule AR-300 / AR-301] (Repository Pattern inside domain).
library;

import '../entities/property.dart';
import '../entities/property_type.dart';
import '../entities/property_settings.dart';

abstract class PropertyRepository {
  Future<List<Property>> getProperties({bool includeArchived = false});
  Future<Property?> getPropertyById(int id);
  Future<Property?> getPropertyByUuid(String uuid);
  Future<int> createProperty(Property property);
  Future<void> updateProperty(Property property);
  Future<void> archiveProperty(int id);
  Future<void> unarchiveProperty(int id);
  Future<List<PropertyType>> getPropertyTypes();
  Future<List<PropertySettings>> getPropertySettings(int propertyId);
  Future<void> savePropertySetting(int propertyId, String key, String value);
  Future<String?> getPropertySettingValue(int propertyId, String key);
}
