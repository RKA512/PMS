/// Why the file exists:
/// SQLite implementation of the BookingRepository interface.
/// Implements [AR-302 (Repository Implementation inside data/repositories)] and database actions in [Flow 04].
/// Ensures transactional integrity using sqflite's transaction runner block for atomic multi-inserts.
library;

import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final DatabaseHelper _dbHelper;

  BookingRepositoryImpl(this._dbHelper);

  @override
  Future<Booking> createBooking(Booking booking, List<int> unitIds, List<int> guestIds) async {
    final db = await _dbHelper.database;
    
    // DB-026 Action: Execute atomically inside a single multi-table TRANSACTION
    late final int bookingId;
    await db.transaction((txn) async {
      // 1. Insert Core Booking Row
      bookingId = await txn.insert(
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

      // 2. Insert Units Linked (booking_units)
      for (final id in unitIds) {
        await txn.insert(
          'booking_units',
          {
            'uuid': '${booking.uuid}_unit_$id',
            'booking_id': bookingId,
            'unit_id': id,
            'start_date': booking.checkInDate.toIso8601String(),
            'end_date': booking.checkOutDate.toIso8601String(),
            'nightly_rate': 0, // In PMS flow, nightly_rate can be calculated or entered
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        // Update room status to reserved
        await txn.update(
          'units',
          {'status': 'reserved'},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      // 3. Insert Multiple Guests (booking_guests)
      for (final id in guestIds) {
        await txn.insert(
          'booking_guests',
          {
            'booking_id': bookingId,
            'guest_id': id,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }
    });

    return booking.copyWith(id: bookingId);
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
    
    // Find overlapping records in booking_units and active bookings
    final query = '''
      SELECT COUNT(*) as count 
      FROM booking_units bu
      JOIN bookings b ON bu.booking_id = b.id
      WHERE bu.unit_id = ? 
        AND b.status NOT IN ('cancelled', 'checkedOut')
        AND (
          (bu.start_date < ? AND bu.end_date > ?)
        )
    ''';

    // Dates mapped as ISO8601 string
    final sStr = end.toIso8601String();
    final eStr = start.toIso8601String();
    
    final result = await db.rawQuery(query, [unitId, sStr, eStr]);
    final count = result.first['count'] as int? ?? 0;
    return count == 0;
  }

  @override
  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required int updatedByUserId,
  }) async {
    final db = await _dbHelper.database;
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
