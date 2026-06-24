/// Why this file exists:
/// Abstract repository contract for Unit and Unit Type operations.
/// Follows [Architecture Rule AR-300 / AR-301] (Repository Pattern inside domain).
library;

import '../entities/unit.dart';
import '../entities/unit_type.dart';

abstract class UnitRepository {
  Future<List<Unit>> getUnits({required int propertyId, bool includeArchived = false});
  Future<Unit?> getUnitById(int id);
  Future<Unit?> getUnitByUuid(String uuid);
  Future<int> createUnit(Unit unit);
  Future<void> updateUnit(Unit unit);
  Future<void> archiveUnit(int id);
  Future<void> unarchiveUnit(int id);
  Future<void> updateUnitStatus({required int unitId, required String status});
  Future<List<UnitType>> getUnitTypes();
}
