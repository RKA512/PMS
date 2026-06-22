/// Why the file exists:
/// Use Case for generating a new Booking safely and logging the event.
/// Implements [Application Flows Flow 04] and [Business Rules BR-303 (Overlapping protection)].
/// Returns true/Booking or throws a clear BusinessRuleFailure upon overlapping values.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository _repository;
  final AuditService _auditService;

  CreateBookingUseCase(this._repository, this._auditService);

  Future<Booking> execute({
    required int propertyId,
    required int primaryGuestId,
    required String bookingNumber,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required List<int> unitIds,
    required List<int> additionalGuestIds,
    required int createdByUserId,
    String? source,
    String? notes,
  }) async {
    if (checkInDate.isAfter(checkOutDate) || checkInDate == checkOutDate) {
      throw const ValidationFailure(
        code: 'INVALID_DATES',
        message: 'تاريخ الدخول يجب أن يكون قبل تاريخ الخروج (Check-In must be before Check-Out).',
      );
    }

    if (unitIds.isEmpty) {
      throw const ValidationFailure(
        code: 'MISSING_UNITS',
        message: 'يجب اختيار وحدة سكنية واحدة على الأقل لإتمام الحجز (At least one unit must be selected).',
      );
    }

    // BR-303: Verify check-in availability overlap across all unit targets
    for (final unitId in unitIds) {
      final available = await _repository.isUnitAvailable(
        unitId: unitId,
        start: checkInDate,
        end: checkOutDate,
      );
      if (!available) {
        throw BusinessRuleFailure(
          code: 'UNIT_OVERLAP',
          message: 'الوحدة المحددة (رقم $unitId) غير متاحة خلال الفترات الزمنية المطلوبة (Unit overlaps with existing reservation).',
        );
      }
    }

    final now = DateTime.now();
    final booking = Booking(
      uuid: const Uuid().v4(),
      propertyId: propertyId,
      primaryGuestId: primaryGuestId,
      bookingNumber: bookingNumber,
      status: BookingStatus.reserved,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      createdBy: createdByUserId,
      source: source,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    // Save Booking
    final List<int> allGuests = [primaryGuestId, ...additionalGuestIds];
    final savedBooking = await _repository.createBooking(booking, unitIds, allGuests);

    // Implements Flow 04 step 8 (Audit Logging)
    await _auditService.log(
      propertyId: propertyId,
      userId: createdByUserId,
      entityType: 'booking',
      entityId: savedBooking.id!,
      action: 'Create Booking',
      description: 'إنشاء حجز جديد برقم ${savedBooking.bookingNumber} للنزيل $primaryGuestId',
      newValues: {
        'booking_number': savedBooking.bookingNumber,
        'units': unitIds,
        'guests': allGuests,
      },
    );

    return savedBooking;
  }
}
