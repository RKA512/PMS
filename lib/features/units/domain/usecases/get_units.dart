/// Why this file exists:
/// Use case for fetching unit listings.
library;

import '../entities/unit.dart';
import '../repositories/unit_repository.dart';

class GetUnits {
  final UnitRepository repository;

  GetUnits(this.repository);

  Future<List<Unit>> call({required int propertyId, bool includeArchived = false}) async {
    return await repository.getUnits(propertyId: propertyId, includeArchived: includeArchived);
  }
}
