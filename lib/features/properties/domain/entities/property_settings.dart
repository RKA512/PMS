/// Why this file exists:
/// Standard Domain Entity for Property Settings (key/value operational attributes).
/// Implements [Domain Model Property Settings] structure.
library;

class PropertySettings {
  final int? id;
  final int propertyId;
  final String settingKey;
  final String settingValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PropertySettings({
    this.id,
    required this.propertyId,
    required this.settingKey,
    required this.settingValue,
    required this.createdAt,
    required this.updatedAt,
  });
}
