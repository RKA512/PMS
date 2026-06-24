/// Why the file exists:
/// Interface contract for Booking access.
/// Implements [Repository Pattern AR-300 / AR-301] and [Business Rules section 6].
library;

import '../entities/booking.dart';

abstract class BookingRepository {
  Future<int> insertBookingRow(Booking booking);
  Future<void> insertBookingUnit({required int bookingId, required int unitId, required DateTime startDate, required DateTime endDate, required String uuid});
  Future<void> insertBookingGuest({required int bookingId, required int guestId});
  Future<void> updateBooking(Booking booking);
  Future<Booking?> getBookingById(int id);
  Future<Booking?> getBookingByNumber(String bookingNumber);
  Future<List<Booking>> getBookingsForProperty(int propertyId);
  
  /// Verifies if the specified unit is available during the selection window.
  /// Implements [Business Rules BR-303 (strictly no overlapping bookings on same unit)].
  Future<bool> isUnitAvailable({
    required int unitId,
    required DateTime start,
    required DateTime end,
    int? excludeBookingId,
  });

  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required int updatedByUserId,
  });

  Future<List<int>> getUnitIdsForBooking(int bookingId);
  Future<List<int>> getGuestIdsForBooking(int bookingId);
}
