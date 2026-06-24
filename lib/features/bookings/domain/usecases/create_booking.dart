/// Why the file exists:
/// Use Case for generating a new Booking safely and logging the event.
/// Implements [Application Flows Flow 04] and [Business Rules BR-303 (Overlapping protection)].
/// Returns true/Booking or throws a clear BusinessRuleFailure upon overlapping values.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/common/enums/unit_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../../properties/domain/repositories/property_repository.dart';
import '../../../units/domain/repositories/unit_repository.dart';
import '../../../guests/domain/repositories/guest_repository.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/booking_domain_service.dart';

class CreateBookingUseCase {
  final BookingRepository _repository;
  final BookingDomainService _bookingDomainService;
  final AuditLogger _auditService;
  final PropertyRepository _propertyRepository;
  final UnitRepository _unitRepository;
  final GuestRepository _guestRepository;

  CreateBookingUseCase(
    this._repository,
    this._bookingDomainService,
    this._auditService,
    this._propertyRepository,
    this._unitRepository,
    this._guestRepository,
  );

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
    // Domain Rule: Ensure Property is not archived
    final property = await _propertyRepository.getPropertyById(propertyId);
    if (property == null || property.deletedAt != null || property.status.toLowerCase() == 'archived') {
      throw const BusinessRuleFailure(
        code: 'PROPERTY_ARCHIVED',
        message: 'لا يمكن إنشاء حجز لعقار مؤرشف (Cannot create booking for an archived property).',
      );
    }

    // Domain Rule: Ensure primary guest is not archived
    final primaryGuest = await _guestRepository.getGuestById(primaryGuestId);
    if (primaryGuest == null || primaryGuest.deletedAt != null) {
      throw const BusinessRuleFailure(
        code: 'GUEST_ARCHIVED',
        message: 'لا يمكن إنشاء حجز لضيف مؤرشف (Cannot create booking for an archived guest).',
      );
    }

    // Domain Rule: Ensure additional guests are not archived
    for (final guestId in additionalGuestIds) {
      final guest = await _guestRepository.getGuestById(guestId);
      if (guest == null || guest.deletedAt != null) {
        throw const BusinessRuleFailure(
          code: 'GUEST_ARCHIVED',
          message: 'لا يمكن إنشاء حجز لضيف مؤرشف (Cannot create booking for an archived guest).',
        );
      }
    }

    // Domain Rule: Ensure all units are not archived
    for (final unitId in unitIds) {
      final unit = await _unitRepository.getUnitById(unitId);
      if (unit == null || unit.deletedAt != null || unit.status == UnitStatus.archived) {
        throw const BusinessRuleFailure(
          code: 'UNIT_ARCHIVED',
          message: 'لا يمكن إنشاء حجز لوحدة سكنية مؤرشفة (Cannot create booking for an archived unit).',
        );
      }
    }

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

    // Save Booking via BookingDomainService
    final List<int> allGuests = [primaryGuestId, ...additionalGuestIds];
    final savedBooking = await _bookingDomainService.createBookingAggregate(
      booking: booking,
      unitIds: unitIds,
      guestIds: allGuests,
    );

    // Flow 04 step 8 (Audit Logging) moved to Use Case
    await _auditService.log(
      propertyId: savedBooking.propertyId,
      userId: createdByUserId,
      entityType: 'booking',
      entityId: savedBooking.id!,
      action: 'Create Booking',
      description: 'إنشاء حجز جديد برقم ${savedBooking.bookingNumber} للنزيل ${savedBooking.primaryGuestId}',
      newValues: {
        'booking_number': savedBooking.bookingNumber,
        'units': unitIds,
        'guests': allGuests,
      },
    );

    return savedBooking;
  }
}
