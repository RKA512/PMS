/// Why this file exists:
/// Use case for saving/adding an individual guest contact directly.
library;

import '../entities/guest_contact.dart';
import '../repositories/guest_repository.dart';

class SaveGuestContact {
  final GuestRepository _repository;

  SaveGuestContact(this._repository);

  Future<void> call(GuestContact contact) async {
    await _repository.saveGuestContact(contact);
  }
}
