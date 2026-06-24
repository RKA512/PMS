/// Why this file exists:
/// Riverpod state providers for Property and Property Settings.
/// Handles lifecycle fetching, background refreshes, and active selection.
/// Satisfies [Architecture Rule AR-011 (Riverpod management)].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/property_settings.dart';
import '../../domain/repositories/property_repository.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/usecases/get_properties.dart';
import '../../domain/usecases/create_property.dart';
import '../../domain/usecases/update_property.dart';
import '../../domain/usecases/archive_property.dart';
import '../../domain/usecases/unarchive_property.dart';
import '../../domain/usecases/get_property_types.dart';
import '../../domain/usecases/property_settings_usecases.dart';

// Repository Provider
final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepositoryImpl();
});

// Use Case Providers
final getPropertiesUseCaseProvider = Provider<GetProperties>((ref) {
  return GetProperties(ref.watch(propertyRepositoryProvider));
});

final createPropertyUseCaseProvider = Provider<CreateProperty>((ref) {
  return CreateProperty(
    ref.watch(propertyRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final updatePropertyUseCaseProvider = Provider<UpdateProperty>((ref) {
  return UpdateProperty(
    ref.watch(propertyRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final archivePropertyUseCaseProvider = Provider<ArchiveProperty>((ref) {
  return ArchiveProperty(
    ref.watch(propertyRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final unarchivePropertyUseCaseProvider = Provider<UnarchiveProperty>((ref) {
  return UnarchiveProperty(
    ref.watch(propertyRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final getPropertyTypesUseCaseProvider = Provider<GetPropertyTypes>((ref) {
  return GetPropertyTypes(ref.watch(propertyRepositoryProvider));
});

final getPropertySettingsUseCaseProvider = Provider<GetPropertySettings>((ref) {
  return GetPropertySettings(ref.watch(propertyRepositoryProvider));
});

final savePropertySettingUseCaseProvider = Provider<SavePropertySetting>((ref) {
  return SavePropertySetting(ref.watch(propertyRepositoryProvider));
});

// Currently Selected / Active Property Provider
final selectedPropertyProvider = StateProvider<Property?>((ref) => null);

// Reactive Properties List StateNotifier and Provider
class PropertiesListNotifier extends StateNotifier<AsyncValue<List<Property>>> {
  final GetProperties _getProperties;

  PropertiesListNotifier(this._getProperties) : super(const AsyncValue.loading()) {
    fetchProperties();
  }

  Future<void> fetchProperties({bool includeArchived = false}) async {
    state = const AsyncValue.loading();
    try {
      final properties = await _getProperties(includeArchived: includeArchived);
      state = AsyncValue.data(properties);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final propertiesListProvider = StateNotifierProvider<PropertiesListNotifier, AsyncValue<List<Property>>>((ref) {
  return PropertiesListNotifier(ref.watch(getPropertiesUseCaseProvider));
});

// Future Provider for Property Types
final propertyTypesFutureProvider = FutureProvider<List<PropertyType>>((ref) async {
  return await ref.watch(getPropertyTypesUseCaseProvider)();
});

// Property Settings Family Provider
final propertySettingsProvider = FutureProvider.family<List<PropertySettings>, int>((ref, propertyId) async {
  return await ref.watch(getPropertySettingsUseCaseProvider)(propertyId);
});
