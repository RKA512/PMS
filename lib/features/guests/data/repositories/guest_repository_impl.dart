/// Why this file exists:
/// Implementation of GuestRepository contract.
/// Executes SQLite queries via DatabaseHelper and records audit entries.
library;

import '../../../../core/database/database_helper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/guest.dart';
import '../../domain/entities/guest_contact.dart';
import '../../domain/repositories/guest_repository.dart';
import '../models/guest_model.dart';
import '../models/guest_contact_model.dart';

class GuestRepositoryImpl implements GuestRepository {
  final _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<Guest>> getGuests(int accountId, {bool includeArchived = false}) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps;

      if (includeArchived) {
        maps = await db.query(
          'guests',
          where: 'account_id = ?',
          whereArgs: [accountId],
          orderBy: 'full_name ASC',
        );
      } else {
        maps = await db.query(
          'guests',
          where: 'account_id = ? AND deleted_at IS NULL',
          whereArgs: [accountId],
          orderBy: 'full_name ASC',
        );
      }

      final List<Guest> guests = [];
      for (final map in maps) {
        final guestNoContacts = GuestModel.fromMap(map);
        final contactsMaps = await db.query(
          'guest_contacts',
          where: 'guest_id = ?',
          whereArgs: [guestNoContacts.id],
        );
        final contacts = contactsMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
        guests.add(guestNoContacts.copyWith(contacts: contacts));
      }
      return guests;
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_GUESTS_FAILED',
        message: 'حدث خطأ أثناء جلب قائمة الضيوف (Error fetching guests: $e)',
      );
    }
  }

  @override
  Future<Guest?> getGuestById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'guests',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final guestNoContacts = GuestModel.fromMap(maps.first);
      final contactsMaps = await db.query(
        'guest_contacts',
        where: 'guest_id = ?',
        whereArgs: [id],
      );
      final contacts = contactsMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
      return guestNoContacts.copyWith(contacts: contacts);
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_GUEST_BY_ID_FAILED',
        message: 'حدث خطأ أثناء جلب بيانات الضيف (Error fetching guest by id: $e)',
      );
    }
  }

  @override
  Future<Guest?> getGuestByDocument(int accountId, String documentType, String documentNumber) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'guests',
        where: 'account_id = ? AND document_type = ? AND document_number = ? AND deleted_at IS NULL',
        whereArgs: [accountId, documentType, documentNumber],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final guestNoContacts = GuestModel.fromMap(maps.first);
      final contactsMaps = await db.query(
        'guest_contacts',
        where: 'guest_id = ?',
        whereArgs: [guestNoContacts.id],
      );
      final contacts = contactsMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
      return guestNoContacts.copyWith(contacts: contacts);
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_GUEST_BY_DOCUMENT_FAILED',
        message: 'حدث خطأ أثناء التحقق من وثيقة الضيف (Error checking guest document: $e)',
      );
    }
  }

  @override
  Future<List<Guest>> searchGuests(int accountId, String query, {bool includeArchived = false}) async {
    if (query.trim().isEmpty) {
      return getGuests(accountId, includeArchived: includeArchived);
    }
    try {
      final db = await _dbHelper.database;
      final wildcard = '%$query%';
      
      String whereString = 'account_id = ? AND (full_name LIKE ? OR phone LIKE ? OR email LIKE ? OR document_number LIKE ?)';
      List<dynamic> whereArgs = [accountId, wildcard, wildcard, wildcard, wildcard];

      if (!includeArchived) {
        whereString += ' AND deleted_at IS NULL';
      }

      final maps = await db.query(
        'guests',
        where: whereString,
        whereArgs: whereArgs,
        orderBy: 'full_name ASC',
      );

      final List<Guest> guests = [];
      for (final map in maps) {
        final guestNoContacts = GuestModel.fromMap(map);
        final contactsMaps = await db.query(
          'guest_contacts',
          where: 'guest_id = ?',
          whereArgs: [guestNoContacts.id],
        );
        final contacts = contactsMaps.map((cMap) => GuestContactModel.fromMap(cMap)).toList();
        guests.add(guestNoContacts.copyWith(contacts: contacts));
      }
      return guests;
    } catch (e) {
      throw DatabaseFailure(
        code: 'SEARCH_GUESTS_FAILED',
        message: 'حدث خطأ أثناء البحث عن الضيوف (Error searching guests: $e)',
      );
    }
  }

  @override
  Future<int> createGuest(Guest guest, int userId) async {
    try {
      final db = await _dbHelper.database;
      return await db.transaction((txn) async {
        final guestMap = GuestModel.toMap(guest);
        final id = await txn.insert('guests', guestMap);

                // Save contacts if exist
        for (final contact in guest.contacts) {
          final contactMap = GuestContactModel.toMap(contact.copyWith(guestId: id));
          await txn.insert('guest_contacts', contactMap);
        }

        return id;
      });
    } catch (e) {
      throw DatabaseFailure(
        code: 'CREATE_GUEST_FAILED',
        message: 'فشل إنشاء الضيف في قاعدة البيانات (Error inserting guest: $e)',
      );
    }
  }

  @override
  Future<void> updateGuest(Guest guest, int userId) async {
    if (guest.id == null) {
      throw const DatabaseFailure(
        code: 'UPDATE_GUEST_MISSING_ID',
        message: 'معرّف الضيف مفقود لتحديث البيانات (Guest ID is required for update)',
      );
    }
    try {
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        final guestMap = GuestModel.toMap(guest);
        await txn.update(
          'guests',
          guestMap,
          where: 'id = ?',
          whereArgs: [guest.id],
        );

        // Update contacts by recreating them inside the transaction safely
        await txn.delete(
          'guest_contacts',
          where: 'guest_id = ?',
          whereArgs: [guest.id],
        );
        for (final contact in guest.contacts) {
          final contactMap = GuestContactModel.toMap(contact.copyWith(guestId: guest.id));
          await txn.insert('guest_contacts', contactMap);
        }
      });
    } catch (e) {
      throw DatabaseFailure(
        code: 'UPDATE_GUEST_FAILED',
        message: 'فشل تحديث بيانات الضيف (Error updating guest: $e)',
      );
    }
  }

  @override
  Future<void> archiveGuest(int id, int userId) async {
    try {
      final db = await _dbHelper.database;
      final oldGuest = await getGuestById(id);
      if (oldGuest == null) return;

      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        await txn.update(
          'guests',
          {'deleted_at': now, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw DatabaseFailure(
        code: 'ARCHIVE_GUEST_FAILED',
        message: 'فشل أرشفة الضيف في قاعدة البيانات (Error archiving guest: $e)',
      );
    }
  }

  @override
  Future<void> unarchiveGuest(int id, int userId) async {
    try {
      final db = await _dbHelper.database;
      final oldGuest = await getGuestById(id);
      if (oldGuest == null) return;

      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        await txn.update(
          'guests',
          {'deleted_at': null, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw DatabaseFailure(
        code: 'UNARCHIVE_GUEST_FAILED',
        message: 'فشل استعادة الضيف في قاعدة البيانات (Error unarchiving guest: $e)',
      );
    }
  }

  @override
  Future<List<GuestContact>> getGuestContacts(int guestId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'guest_contacts',
        where: 'guest_id = ?',
        whereArgs: [guestId],
      );
      return maps.map((map) => GuestContactModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure(
        code: 'GET_GUEST_CONTACTS_FAILED',
        message: 'فشل جلب اتصالات الضيف (Error fetching guest contacts: $e)',
      );
    }
  }

  @override
  Future<void> saveGuestContact(GuestContact contact) async {
    try {
      final db = await _dbHelper.database;
      final map = GuestContactModel.toMap(contact);
      if (contact.id == null) {
        await db.insert('guest_contacts', map);
      } else {
        await db.update(
          'guest_contacts',
          map,
          where: 'id = ?',
          whereArgs: [contact.id],
        );
      }
    } catch (e) {
      throw DatabaseFailure(
        code: 'SAVE_GUEST_CONTACT_FAILED',
        message: 'فشل حفظ اتصال الضيف (Error saving guest contact: $e)',
      );
    }
  }

  @override
  Future<void> deleteGuestContact(int contactId) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'guest_contacts',
        where: 'id = ?',
        whereArgs: [contactId],
      );
    } catch (e) {
      throw DatabaseFailure(
        code: 'DELETE_GUEST_CONTACT_FAILED',
        message: 'فشل حذف اتصال الضيف (Error deleting guest contact: $e)',
      );
    }
  }
}
