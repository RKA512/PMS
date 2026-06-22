/// Why this file exists:
/// Use case for retrieving guests list. Supports optional inclusion of archived records.
library;

import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class GetGuests {
  final GuestRepository _repository;

  GetGuests(this._repository);

  Future<List<Guest>> call(int accountId, {bool includeArchived = false}) async {
    return await _repository.getGuests(accountId, includeArchived: includeArchived);
  }
}
