/// Why this file exists:
/// Riverpod state providers for Guest management.
/// Implements [Architecture Rule AR-011] and handles search, states, and operations.
library;

import '../../../../core/providers/session_providers.dart';
import '../../../../core/services/audit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/guest.dart';
import '../../domain/repositories/guest_repository.dart';
import '../../data/repositories/guest_repository_impl.dart';
import '../../domain/usecases/get_guests.dart';
import '../../domain/usecases/create_guest.dart';
import '../../domain/usecases/update_guest.dart';
import '../../domain/usecases/archive_guest.dart';
import '../../domain/usecases/unarchive_guest.dart';
import '../../domain/usecases/search_guests.dart';
import '../../domain/usecases/save_guest_contact.dart';
import '../../domain/usecases/delete_guest_contact.dart';

// Repository Provider
final guestRepositoryProvider = Provider<GuestRepository>((ref) {
  return GuestRepositoryImpl();
});

// Use Case Providers
final getGuestsUseCaseProvider = Provider<GetGuests>((ref) {
  return GetGuests(ref.watch(guestRepositoryProvider));
});

final createGuestUseCaseProvider = Provider<CreateGuest>((ref) {
  return CreateGuest(
    ref.watch(guestRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final updateGuestUseCaseProvider = Provider<UpdateGuest>((ref) {
  return UpdateGuest(
    ref.watch(guestRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final archiveGuestUseCaseProvider = Provider<ArchiveGuest>((ref) {
  return ArchiveGuest(
    ref.watch(guestRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final unarchiveGuestUseCaseProvider = Provider<UnarchiveGuest>((ref) {
  return UnarchiveGuest(
    ref.watch(guestRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final searchGuestsUseCaseProvider = Provider<SearchGuests>((ref) {
  return SearchGuests(ref.watch(guestRepositoryProvider));
});

final saveGuestContactUseCaseProvider = Provider<SaveGuestContact>((ref) {
  return SaveGuestContact(ref.watch(guestRepositoryProvider));
});

final deleteGuestContactUseCaseProvider = Provider<DeleteGuestContact>((ref) {
  return DeleteGuestContact(ref.watch(guestRepositoryProvider));
});

// Search UI query state
final guestSearchQueryProvider = StateProvider<String>((ref) => "");

// Include archived state flag
final guestIncludeArchivedProvider = StateProvider<bool>((ref) => false);

// Reactive Guests List StateNotifier and Provider
class GuestsListNotifier extends StateNotifier<AsyncValue<List<Guest>>> {
  final GetGuests _getGuests;
  final SearchGuests _searchGuests;

  GuestsListNotifier(
    this._getGuests,
    this._searchGuests, {
    AsyncValue<List<Guest>> initialState = const AsyncValue.loading(),
  }) : super(initialState);

  Future<void> _fetchGuestsInternal(int accountId, {String query = "", bool includeArchived = false}) async {
    try {
      final List<Guest> list;
      if (query.trim().isEmpty) {
        list = await _getGuests(accountId, includeArchived: includeArchived);
      } else {
        list = await _searchGuests(accountId, query.trim(), includeArchived: includeArchived);
      }
      state = AsyncValue.data(list);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> fetchGuests(int accountId, {String query = "", bool includeArchived = false}) async {
    state = const AsyncValue.loading();
    await _fetchGuestsInternal(accountId, query: query, includeArchived: includeArchived);
  }
}

final guestsListProvider = StateNotifierProvider<GuestsListNotifier, AsyncValue<List<Guest>>>((ref) {
  final getG = ref.watch(getGuestsUseCaseProvider);
  final searchG = ref.watch(searchGuestsUseCaseProvider);
  final accountId = ref.watch(activeAccountIdProvider);
  final query = ref.watch(guestSearchQueryProvider);
  final includeArchived = ref.watch(guestIncludeArchivedProvider);

  if (accountId == null) {
    return GuestsListNotifier(
      getG,
      searchG,
      initialState: const AsyncValue.data([]),
    );
  }

  final notifier = GuestsListNotifier(getG, searchG);
  // Safely trigger fetch reactively
  Future.microtask(() => notifier._fetchGuestsInternal(accountId, query: query, includeArchived: includeArchived));

  return notifier;
});
