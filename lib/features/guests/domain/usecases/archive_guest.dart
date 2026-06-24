/// Why this file exists:
/// Use case for archiving (soft deleting) a guest.
library;

import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/guest_model.dart';
import '../repositories/guest_repository.dart';

class ArchiveGuest {
  final GuestRepository _repository;
  final AuditLogger _auditService;

  ArchiveGuest(this._repository, this._auditService);

  Future<void> call(int id, int userId) async {
    final oldGuest = await _repository.getGuestById(id);
    if (oldGuest == null) return;
    final oldMap = GuestModel.toMap(oldGuest);

    await _repository.archiveGuest(id, userId);

    // Log Audit Event
    await _auditService.log(
      userId: userId,
      entityType: 'Guest',
      entityId: id,
      action: 'Archive Guest',
      description: 'أرشف الضيف: ${oldGuest.fullName} (Archived guest: ${oldGuest.fullName})',
      oldValues: oldMap,
    );
  }
}
