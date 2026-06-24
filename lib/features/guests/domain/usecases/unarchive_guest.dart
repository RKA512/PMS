/// Why this file exists:
/// Use case for restoring (unarchiving) a guest.
library;

import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/guest_model.dart';
import '../repositories/guest_repository.dart';

class UnarchiveGuest {
  final GuestRepository _repository;
  final AuditLogger _auditService;

  UnarchiveGuest(this._repository, this._auditService);

  Future<void> call(int id, int userId) async {
    final oldGuest = await _repository.getGuestById(id);
    if (oldGuest == null) return;
    final oldMap = GuestModel.toMap(oldGuest);

    await _repository.unarchiveGuest(id, userId);

    // Log Audit Event
    await _auditService.log(
      userId: userId,
      entityType: 'Guest',
      entityId: id,
      action: 'Unarchive Guest',
      description: 'استعاد الضيف: ${oldGuest.fullName} (Restored guest: ${oldGuest.fullName})',
      oldValues: oldMap,
    );
  }
}
