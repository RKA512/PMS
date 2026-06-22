/// Why the file exists:
/// Represents the fundamental Booking entity in the domain model.
/// Implements [Domain Model Booking] and [AR-400 / AR-401 (independent of serializations and Flutter)].
/// Holds core booking parameters.
library;

import '../../../../core/common/enums/booking_status.dart';

class Booking {
  final int? id;
  final String uuid;
  final int propertyId;
  final int primaryGuestId;
  final String bookingNumber;
  final BookingStatus status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final DateTime? actualCheckIn;
  final DateTime? actualCheckOut;
  final String? source;
  final String? notes;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    this.id,
    required this.uuid,
    required this.propertyId,
    required this.primaryGuestId,
    required this.bookingNumber,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    this.actualCheckIn,
    this.actualCheckOut,
    this.source,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Booking copyWith({
    int? id,
    String? uuid,
    int? propertyId,
    int? primaryGuestId,
    String? bookingNumber,
    BookingStatus? status,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    DateTime? actualCheckIn,
    DateTime? actualCheckOut,
    String? source,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      propertyId: propertyId ?? this.propertyId,
      primaryGuestId: primaryGuestId ?? this.primaryGuestId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      status: status ?? this.status,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      actualCheckIn: actualCheckIn ?? this.actualCheckIn,
      actualCheckOut: actualCheckOut ?? this.actualCheckOut,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
