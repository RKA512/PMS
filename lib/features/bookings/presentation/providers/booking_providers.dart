/// Why this file exists:
/// Riverpod state providers for Bookings, including Use Cases, domain services, and repository wiring.
/// Satisfies [Architecture Rule AR-011 (Riverpod management)].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/audit_service.dart';
import '../../../units/presentation/providers/unit_providers.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/services/booking_domain_service.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/edit_booking.dart';
import '../../domain/usecases/cancel_booking.dart';

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
  );
});

final editBookingUseCaseProvider = Provider<EditBookingUseCase>((ref) {
  return EditBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});

final cancelBookingUseCaseProvider = Provider<CancelBookingUseCase>((ref) {
  return CancelBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(auditServiceProvider),
  );
});
