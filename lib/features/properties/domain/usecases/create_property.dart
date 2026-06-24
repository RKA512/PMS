/// Why this file exists:
/// Use case for creating a new property.
/// Asserts non-empty values, generates UUID, and sets creation times.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/property_model.dart';
import '../entities/property.dart';
import '../repositories/property_repository.dart';

class CreateProperty {
  final PropertyRepository repository;
  final AuditLogger auditService;
  final _uuid = const Uuid();

  CreateProperty(this.repository, this.auditService);

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
    required int userId,
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

    final id = await repository.createProperty(property);

    // Log Audit Event
    await auditService.log(
      propertyId: id,
      userId: userId,
      entityType: 'Property',
      entityId: id,
      action: 'Create Property',
      description: 'Created property: ${property.name} with currency ${property.currencyCode}',
      newValues: PropertyModel.toMap(
        property.copyWith(id: id),
      ),
    );

    return id;
  }
}
