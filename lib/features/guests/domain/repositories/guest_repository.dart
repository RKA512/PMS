/// Why this file exists:
/// Contract for GuestRepository following clean architecture domain boundaries.
library;

import '../entities/guest.dart';
import '../entities/guest_contact.dart';

abstract class GuestRepository {
  Future<List<Guest>> getGuests(int accountId, {bool includeArchived = false});
  Future<Guest?> getGuestById(int id);
  Future<Guest?> getGuestByDocument(int accountId, String documentType, String documentNumber);
  Future<List<Guest>> searchGuests(int accountId, String query, {bool includeArchived = false});
  Future<int> createGuest(Guest guest, int userId);
  Future<void> updateGuest(Guest guest, int userId);
  Future<void> archiveGuest(int id, int userId);
  Future<void> unarchiveGuest(int id, int userId);
  Future<List<GuestContact>> getGuestContacts(int guestId);
  Future<void> saveGuestContact(GuestContact contact);
  Future<void> deleteGuestContact(int contactId);
}
