/// Why this file exists:
/// Model representing Property mapping to and from SQLite database structure.
/// Satisfies [Model Rules AR-500 / AR-501] and isolates SQL formats.
library;

import '../../domain/entities/property.dart';

class PropertyModel {
  static Map<String, dynamic> toMap(Property property) {
    return {
      if (property.id != null) 'id': property.id,
      'uuid': property.uuid,
      'account_id': property.accountId,
      'property_type_id': property.propertyTypeId,
      'name': property.name,
      'address': property.address,
      'city': property.city,
      'country': property.country,
      'phone': property.phone,
      'email': property.email,
      'currency_code': property.currencyCode,
      'use_business_days': property.useBusinessDays ? 1 : 0,
      'status': property.status,
      'created_at': property.createdAt.toIso8601String(),
      'updated_at': property.updatedAt.toIso8601String(),
      'deleted_at': property.deletedAt?.toIso8601String(),
    };
  }

  static Property fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      accountId: map['account_id'] as int,
      propertyTypeId: map['property_type_id'] as int,
      name: map['name'] as String,
      address: map['address'] as String?,
      city: map['city'] as String?,
      country: map['country'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      currencyCode: map['currency_code'] as String,
      useBusinessDays: (map['use_business_days'] as int) == 1,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
