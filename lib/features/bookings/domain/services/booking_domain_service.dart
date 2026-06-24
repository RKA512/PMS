/// Why this file exists:
/// Coordinates multiple repositories atomically to handle the creation of a Booking Aggregate.
/// Implements [DEC-018 Domain Services] and [DEC-019 TransactionRunner].
library;

import '../../../../core/contracts/transaction_runner.dart';
import '../../../units/domain/repositories/unit_repository.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

/// Why this Domain Service exists:
/// Following DEC-018, business orchestration must not live in persistence layer repositories.
/// BookingDomainService acts as the pure domain-level orchestrator for atomic bookings transactions.
/// It coordinates multiple repositories (BookingRepository, UnitRepository) to maintain cohesive domain rules.
///
/// Why TransactionRunner exists:
/// TransactionRunner abstracts database-specific transactions (like sqflite's transaction blocks),
/// keeping the domain service completely database-agnostic and 100% testable without real database instances.
///
/// How this supports future Payments and Settlements modules:
/// By isolating transaction orchestration at the domain-service layer, future modules (like Payments and Settlements)
/// can easily participate in existing transactions or coordinate their own multi-aggregate atomic actions.
/// For example, the domain service can easily wrap both booking creation and upfront deposit payment
/// inside a single transaction, ensuring that no booking is finalized without its corresponding payment record.
class BookingDomainService {
  final BookingRepository _bookingRepository;
  final UnitRepository _unitRepository;
  final TransactionRunner _transactionRunner;

  BookingDomainService({
    required BookingRepository bookingRepository,
    required UnitRepository unitRepository,
    required TransactionRunner transactionRunner,
  })  : _bookingRepository = bookingRepository,
        _unitRepository = unitRepository,
        _transactionRunner = transactionRunner;

  /// Orchestrates the creation of a booking aggregate, linking units, attaching guests, and updating unit status.
  Future<Booking> createBookingAggregate({
    required Booking booking,
    required List<int> unitIds,
    required List<int> guestIds,
  }) async {
    return await _transactionRunner.run<Booking>(() async {
      // 1. Insert Booking Core Row and get auto-generated ID
      final int bookingId = await _bookingRepository.insertBookingRow(booking);

      // 2. Insert Units Linked and Update Status to Reserved
      for (final id in unitIds) {
        await _bookingRepository.insertBookingUnit(
          bookingId: bookingId,
          unitId: id,
          startDate: booking.checkInDate,
          endDate: booking.checkOutDate,
          uuid: '${booking.uuid}_unit_$id',
        );

        // Update room status to reserved
        await _unitRepository.updateUnitStatus(
          unitId: id,
          status: 'reserved',
        );
      }

      // 3. Attach Guests
      for (final id in guestIds) {
        await _bookingRepository.insertBookingGuest(
          bookingId: bookingId,
          guestId: id,
        );
      }

      return booking.copyWith(id: bookingId);
    });
  }
}
