/// Why the file exists:
/// Use Case for cancelling an active booking.
/// Implements [Application Flows Flow 09] and state controls in [Business Rules BR-307].
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';

class CancelBookingUseCase {
  final BookingRepository _repository;
  final AuditService _auditService;

  CancelBookingUseCase(this._repository, this._auditService);

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

    // Audit Logging
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
