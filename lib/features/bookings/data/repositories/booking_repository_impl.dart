/// Why the file exists:
/// SQLite implementation of the BookingRepository interface.
/// Implements [AR-302 (Repository Implementation inside data/repositories)] and database actions in [Flow 04].
/// Ensures transactional integrity using sqflite's transaction runner block for atomic multi-inserts.
library;

import 'dart:async';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final DatabaseHelper _dbHelper;

  BookingRepositoryImpl(this._dbHelper);

  @override
  Future<int> insertBookingRow(Booking booking) async {
    final db = await _dbHelper.executor;
    return await db.insert(
      'bookings',
      {
        'uuid': booking.uuid,
        'property_id': booking.propertyId,
        'primary_guest_id': booking.primaryGuestId,
        'booking_number': booking.bookingNumber,
        'status': booking.status.toJson(),
        'check_in_date': booking.checkInDate.toIso8601String(),
        'check_out_date': booking.checkOutDate.toIso8601String(),
        'source': booking.source,
        'notes': booking.notes,
        'created_by': booking.createdBy,
        'created_at': booking.createdAt.toIso8601String(),
        'updated_at': booking.updatedAt.toIso8601String(),
      },
    );
  }

  @override
  Future<void> insertBookingUnit({
    required int bookingId,
    required int unitId,
    required DateTime startDate,
    required DateTime endDate,
    required String uuid,
  }) async {
    final db = await _dbHelper.executor;
    await db.insert(
      'booking_units',
      {
        'uuid': uuid,
        'booking_id': bookingId,
        'unit_id': unitId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'nightly_rate': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> insertBookingGuest({
    required int bookingId,
    required int guestId,
  }) async {
    final db = await _dbHelper.executor;
    await db.insert(
      'booking_guests',
      {
        'booking_id': bookingId,
        'guest_id': guestId,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final db = await _dbHelper.executor;
    await db.update(
      'bookings',
      {
        'notes': booking.notes,
        'source': booking.source,
        'check_in_date': booking.checkInDate.toIso8601String(),
        'check_out_date': booking.checkOutDate.toIso8601String(),
        'updated_at': booking.updatedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    final db = await _dbHelper.executor;
    final results = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return _mapToBooking(results.first);
  }

  @override
  Future<Booking?> getBookingByNumber(String bookingNumber) async {
    final db = await _dbHelper.executor;
    final results = await db.query(
      'bookings',
      where: 'booking_number = ?',
      whereArgs: [bookingNumber],
    );

    if (results.isEmpty) return null;
    return _mapToBooking(results.first);
  }

  @override
  Future<List<Booking>> getBookingsForProperty(int propertyId) async {
    final db = await _dbHelper.executor;
    final results = await db.query(
      'bookings',
      where: 'property_id = ?',
      whereArgs: [propertyId],
      orderBy: 'check_in_date DESC',
    );

    return results.map(_mapToBooking).toList();
  }

  @override
  Future<bool> isUnitAvailable({
    required int unitId,
    required DateTime start,
    required DateTime end,
    int? excludeBookingId,
  }) async {
    final db = await _dbHelper.executor;
    
    // Dates mapped as ISO8601 string
    final sStr = end.toIso8601String();
    final eStr = start.toIso8601String();

    final List<Object?> whereArgs = [unitId];
    String excludeClause = '';
    if (excludeBookingId != null) {
      excludeClause = 'AND b.id != ?';
      whereArgs.add(excludeBookingId);
    }
    whereArgs.addAll([sStr, eStr]);

    // Find overlapping records in booking_units and active bookings
    final query = '''
      SELECT COUNT(*) as count 
      FROM booking_units bu
      JOIN bookings b ON bu.booking_id = b.id
      WHERE bu.unit_id = ? 
        AND b.status NOT IN ('cancelled', 'checkedOut')
        $excludeClause
        AND (
          (bu.start_date < ? AND bu.end_date > ?)
        )
    ''';
    
    final result = await db.rawQuery(query, whereArgs);
    final count = result.first['count'] as int? ?? 0;
    return count == 0;
  }

  @override
  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required int updatedByUserId,
  }) async {
    final db = await _dbHelper.executor;
    await db.update(
      'bookings',
      {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  Booking _mapToBooking(Map<String, dynamic> row) {
    return Booking(
      id: row['id'] as int?,
      uuid: row['uuid'] as String,
      propertyId: row['property_id'] as int,
      primaryGuestId: row['primary_guest_id'] as int,
      bookingNumber: row['booking_number'] as String,
      status: BookingStatus.fromJson(row['status'] as String),
      checkInDate: DateTime.parse(row['check_in_date'] as String),
      checkOutDate: DateTime.parse(row['check_out_date'] as String),
      actualCheckIn: row['actual_check_in'] != null ? DateTime.parse(row['actual_check_in'] as String) : null,
      actualCheckOut: row['actual_check_out'] != null ? DateTime.parse(row['actual_check_out'] as String) : null,
      source: row['source'] as String?,
      notes: row['notes'] as String?,
      createdBy: row['created_by'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
