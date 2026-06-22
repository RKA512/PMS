/// Why this file exists:
/// Use case for fetching list of seeded property types.
library;

import '../entities/property_type.dart';
import '../repositories/property_repository.dart';

class GetPropertyTypes {
  final PropertyRepository repository;

  GetPropertyTypes(this.repository);

  Future<List<PropertyType>> call() async {
    return await repository.getPropertyTypes();
  }
}
