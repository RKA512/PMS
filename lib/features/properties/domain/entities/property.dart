/// Why this file exists:
/// Standard Domain Entity for Property.
/// Implements [Domain Model Property] and satisfies [Architecture Layer Domain Entities are independent of Flutter].
library;

class Property {
  final int? id;
  final String uuid;
  final int accountId;
  final int propertyTypeId;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String? phone;
  final String? email;
  final String currencyCode;
  final bool useBusinessDays;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Property({
    this.id,
    required this.uuid,
    required this.accountId,
    required this.propertyTypeId,
    required this.name,
    this.address,
    this.city,
    this.country,
    this.phone,
    this.email,
    required this.currencyCode,
    required this.useBusinessDays,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Property copyWith({
    int? id,
    String? uuid,
    int? accountId,
    int? propertyTypeId,
    String? name,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? currencyCode,
    bool? useBusinessDays,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Property(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      accountId: accountId ?? this.accountId,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      useBusinessDays: useBusinessDays ?? this.useBusinessDays,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
