/// Why this file exists:
/// Riverpod state providers for Units and Unit Types.
/// Manages loading, updating, and dynamic unit listings of properties.
/// Satisfies [Architecture Rule AR-011] Riverpod standards.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_type.dart';
import '../../domain/repositories/unit_repository.dart';
import '../../data/repositories/unit_repository_impl.dart';
import '../../domain/usecases/get_units.dart';
import '../../domain/usecases/create_unit.dart';
import '../../domain/usecases/update_unit.dart';
import '../../domain/usecases/archive_unit.dart';
import '../../domain/usecases/unarchive_unit.dart';
import '../../domain/usecases/get_unit_types.dart';

// Repository Provider
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return UnitRepositoryImpl();
});

// Use Case Providers
final getUnitsUseCaseProvider = Provider<GetUnits>((ref) {
  return GetUnits(ref.watch(unitRepositoryProvider));
});

final createUnitUseCaseProvider = Provider<CreateUnit>((ref) {
  return CreateUnit(
    ref.watch(unitRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final updateUnitUseCaseProvider = Provider<UpdateUnit>((ref) {
  return UpdateUnit(
    ref.watch(unitRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final archiveUnitUseCaseProvider = Provider<ArchiveUnit>((ref) {
  return ArchiveUnit(
    ref.watch(unitRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final unarchiveUnitUseCaseProvider = Provider<UnarchiveUnit>((ref) {
  return UnarchiveUnit(
    ref.watch(unitRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final getUnitTypesUseCaseProvider = Provider<GetUnitTypes>((ref) {
  return GetUnitTypes(ref.watch(unitRepositoryProvider));
});

// Units List StateNotifier parameterized by Property ID
class UnitsListNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final GetUnits _getUnits;
  final int _propertyId;

  UnitsListNotifier(this._getUnits, this._propertyId) : super(const AsyncValue.loading()) {
    fetchUnits();
  }

  Future<void> fetchUnits({bool includeArchived = false}) async {
    state = const AsyncValue.loading();
    try {
      final units = await _getUnits(propertyId: _propertyId, includeArchived: includeArchived);
      state = AsyncValue.data(units);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final unitsListProvider = StateNotifierProvider.family<UnitsListNotifier, AsyncValue<List<Unit>>, int>((ref, propertyId) {
  return UnitsListNotifier(ref.watch(getUnitsUseCaseProvider), propertyId);
});

// Future Provider for Unit Types
final unitTypesFutureProvider = FutureProvider<List<UnitType>>((ref) async {
  return await ref.watch(getUnitTypesUseCaseProvider)();
});
