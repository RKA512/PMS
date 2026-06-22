/// Why this file exists:
/// Use case to fetch properties.
/// Restructured according to AR-101 Domain layer principles.
library;

import '../entities/property.dart';
import '../repositories/property_repository.dart';

class GetProperties {
  final PropertyRepository repository;

  GetProperties(this.repository);

  Future<List<Property>> call({bool includeArchived = false}) async {
    return await repository.getProperties(includeArchived: includeArchived);
  }
}
