/// Why this file exists:
/// Use case for soft deleting (archiving) units safely.
library;

import '../repositories/unit_repository.dart';

class ArchiveUnit {
  final UnitRepository repository;

  ArchiveUnit(this.repository);

  Future<void> call(int id) async {
    await repository.archiveUnit(id);
  }
}
