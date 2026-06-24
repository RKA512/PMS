/// Why this file exists:
/// Riverpod state providers for Bookings, including Use Cases, domain services, and repository wiring.
/// Satisfies [Architecture Rule AR-011 (Riverpod management)].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/audit_service.dart';
import '../../../units/presentation/providers/unit_providers.dart';
import '../../../properties/presentation/providers/property_providers.dart';
import '../../../guests/presentation/providers/guest_providers.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../guests/domain/entities/guest.dart';
import '../../../units/domain/entities/unit.dart';
import '../../../guests/domain/usecases/get_guests.dart';
import '../../../units/domain/usecases/get_units.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/services/booking_domain_service.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/edit_booking.dart';
import '../../domain/usecases/cancel_booking.dart';
import '../../domain/entities/booking.dart';

// Repository Provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(DatabaseHelper.instance);
});

// Domain Service Provider
final bookingDomainServiceProvider = Provider<BookingDomainService>((ref) {
  return BookingDomainService(
    bookingRepository: ref.watch(bookingRepositoryProvider),
    unitRepository: ref.watch(unitRepositoryProvider),
    transactionRunner: ref.watch(transactionRunnerProvider),
  );
});

// Use Case Providers
final createBookingUseCaseProvider = Provider<CreateBookingUseCase>((ref) {
  return CreateBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(unitRepositoryProvider),
    ref.watch(guestRepositoryProvider),
  );
});

final editBookingUseCaseProvider = Provider<EditBookingUseCase>((ref) {
  return EditBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(unitRepositoryProvider),
    ref.watch(guestRepositoryProvider),
  );
});

final cancelBookingUseCaseProvider = Provider<CancelBookingUseCase>((ref) {
  return CancelBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

// Reactive Bookings List StateNotifier and Provider
class BookingsListNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository _repository;
  final int? _propertyId;

  BookingsListNotifier(this._repository, this._propertyId) : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    if (_propertyId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getBookingsForProperty(_propertyId!);
      state = AsyncValue.data(list);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final bookingsListProvider = StateNotifierProvider.family<BookingsListNotifier, AsyncValue<List<Booking>>, int?>((ref, propertyId) {
  return BookingsListNotifier(ref.watch(bookingRepositoryProvider), propertyId);
});

final bookingUnitIdsProvider = FutureProvider.family<List<int>, int>((ref, bookingId) async {
  return await ref.watch(bookingRepositoryProvider).getUnitIdsForBooking(bookingId);
});

final bookingGuestIdsProvider = FutureProvider.family<List<int>, int>((ref, bookingId) async {
  return await ref.watch(bookingRepositoryProvider).getGuestIdsForBooking(bookingId);
});

// Fetch ONLY active (unarchived) guests for selection in Booking Dialog
final activeGuestsForBookingProvider = FutureProvider<List<Guest>>((ref) async {
  final accountId = ref.watch(activeAccountIdProvider);
  if (accountId == null) return [];
  final getGuests = ref.watch(getGuestsUseCaseProvider);
  return await getGuests(accountId, includeArchived: false);
});

// Fetch ONLY active (unarchived) units for selection in Booking Dialog
final activeUnitsForBookingProvider = FutureProvider.family<List<Unit>, int>((ref, propertyId) async {
  final getUnits = ref.watch(getUnitsUseCaseProvider);
  return await getUnits(propertyId: propertyId, includeArchived: false);
});

