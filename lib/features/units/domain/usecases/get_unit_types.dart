/// Why this file exists:
/// Use case to list seeded unit types from SQLite.
library;

import '../entities/unit_type.dart';
import '../repositories/unit_repository.dart';

class GetUnitTypes {
  final UnitRepository repository;

  GetUnitTypes(this.repository);

  Future<List<UnitType>> call() async {
    return await repository.getUnitTypes();
  }
}
