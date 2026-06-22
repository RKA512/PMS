/// Why this file exists:
/// Use case for archiving (soft deleting) a guest.
library;

import '../repositories/guest_repository.dart';

class ArchiveGuest {
  final GuestRepository _repository;

  ArchiveGuest(this._repository);

  Future<void> call(int id, int userId) async {
    await _repository.archiveGuest(id, userId);
  }
}
