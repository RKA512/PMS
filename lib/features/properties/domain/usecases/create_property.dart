/// Why this file exists:
/// Use case for creating a new property.
/// Asserts non-empty values, generates UUID, and sets creation times.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class CreateProperty {
  final PropertyRepository repository;
  final _uuid = const Uuid();

  CreateProperty(this.repository);

  Future<int> call({
    required int accountId,
    required int propertyTypeId,
    required String name,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? email,
    required String currencyCode,
    required bool useBusinessDays,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'PROPERTY_NAME_EMPTY',
        message: 'اسم العقار لا يمكن أن يكون فارغاً (Property name cannot be empty)',
      );
    }
    if (currencyCode.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'BASE_CURRENCY_REQUIRED',
        message: 'يجب تقديم رمز العملة الرسمي (A base currency code is required)',
      );
    }

    final now = DateTime.now();
    final property = Property(
      uuid: _uuid.v4(),
      accountId: accountId,
      propertyTypeId: propertyTypeId,
      name: name.trim(),
      address: address?.trim(),
      city: city?.trim(),
      country: country?.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      currencyCode: currencyCode.trim().toUpperCase(),
      useBusinessDays: useBusinessDays,
      status: 'Active',
      createdAt: now,
      updatedAt: now,
    );

    return await repository.createProperty(property);
  }
}
