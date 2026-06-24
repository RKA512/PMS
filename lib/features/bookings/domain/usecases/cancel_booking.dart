/// Why the file exists:
/// Use Case for cancelling an active booking.
/// Implements [Application Flows Flow 09] and state controls in [Business Rules BR-307].
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../../units/domain/repositories/unit_repository.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase {
  final BookingRepository _repository;
  final AuditLogger _auditService;
  final UnitRepository _unitRepository;

  CancelBookingUseCase(this._repository, this._auditService, this._unitRepository);

  Future<void> execute({
    required Booking booking,
    required int updatedByUserId,
  }) async {
    // Cannot cancel if checked out or already cancelled
    if (booking.status == BookingStatus.checkedOut) {
      throw const BusinessRuleFailure(
        code: 'CANCEL_FORBIDDEN',
        message: 'الحجز منتهي بالفعل وتم خروج النزيل، لا يمكن إلغاؤه (Cannot cancel a booking that is already checked out).',
      );
    }
    
    if (booking.status == BookingStatus.cancelled) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CANCELLED',
        message: 'الحجز ملغي بالفعل مسبقاً (This booking is already cancelled).',
      );
    }

    await _repository.updateBookingStatus(
      bookingId: booking.id!,
      status: BookingStatus.cancelled.toJson(),
      updatedByUserId: updatedByUserId,
    );

    // Release associated units back to available status
    final unitIds = await _repository.getUnitIdsForBooking(booking.id!);
    for (final unitId in unitIds) {
      await _unitRepository.updateUnitStatus(unitId: unitId, status: 'available');
    }

    await _auditService.log(
      propertyId: booking.propertyId,
      userId: updatedByUserId,
      entityType: 'booking',
      entityId: booking.id!,
      action: 'Cancel Booking',
      description: 'إلغاء الحجز رقم ${booking.bookingNumber} بنجاح.',
    );
  }
}
