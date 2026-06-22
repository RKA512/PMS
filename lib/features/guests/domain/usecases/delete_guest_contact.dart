/// Why this file exists:
/// Use case for deleting an individual guest contact directly.
library;

import '../repositories/guest_repository.dart';

class DeleteGuestContact {
  final GuestRepository _repository;

  DeleteGuestContact(this._repository);

  Future<void> call(int contactId) async {
    await _repository.deleteGuestContact(contactId);
  }
}
