/// Why this file exists:
/// Use case for soft deleting (archiving) properties safely.
library;

import '../repositories/property_repository.dart';

class ArchiveProperty {
  final PropertyRepository repository;

  ArchiveProperty(this.repository);

  Future<void> call(int id) async {
    await repository.archiveProperty(id);
  }
}
