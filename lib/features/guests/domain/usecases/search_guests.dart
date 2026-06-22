/// Why this file exists:
/// Use case for searching guests by phrase query.
library;

import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class SearchGuests {
  final GuestRepository _repository;

  SearchGuests(this._repository);

  Future<List<Guest>> call(int accountId, String query, {bool includeArchived = false}) async {
    return await _repository.searchGuests(accountId, query, includeArchived: includeArchived);
  }
}
