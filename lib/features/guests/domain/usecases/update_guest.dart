/// Why this file exists:
/// Use case for updating a guest. Validates updated fields and handles duplicate verification.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/guest_model.dart';
import '../entities/guest.dart';
import '../repositories/guest_repository.dart';

class UpdateGuest {
  final GuestRepository _repository;
  final AuditLogger _auditService;

  UpdateGuest(this._repository, this._auditService);

  Future<void> call(Guest guest, int userId) async {
    if (guest.id == null) {
      throw const ValidationFailure(
        code: 'GUEST_ID_MISSING',
        message: 'معرّف الضيف مفقود لتحديث البيانات (Guest ID is missing)',
      );
    }

    // 1. Name presence validation
    if (guest.fullName.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'GUEST_NAME_EMPTY',
        message: 'اسم الضيف لا يمكن أن يكون فارغاً (Guest name cannot be empty)',
      );
    }

    // 2. Email format validation
    if (guest.email != null && guest.email!.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(guest.email!.trim())) {
        throw const ValidationFailure(
          code: 'GUEST_EMAIL_INVALID',
          message: 'صيغة البريد الإلكتروني غير صالحة (Invalid email format)',
        );
      }
    }

    // 3. Phone format validation
    if (guest.phone != null && guest.phone!.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');
      if (!phoneRegex.hasMatch(guest.phone!.trim())) {
        throw const ValidationFailure(
          code: 'GUEST_PHONE_INVALID',
          message: 'رقم الهاتف المكتوب غير صالح (Invalid phone format)',
        );
      }
    }

    // 4. Duplicate document prevention
    if (guest.documentType != null && guest.documentType!.trim().isNotEmpty &&
        guest.documentNumber != null && guest.documentNumber!.trim().isNotEmpty) {
      final existing = await _repository.getGuestByDocument(
        guest.accountId,
        guest.documentType!.trim(),
        guest.documentNumber!.trim(),
      );
      if (existing != null && existing.id != guest.id) {
        throw const ValidationFailure(
          code: 'GUEST_DOCUMENT_DUPLICATE',
          message: 'هذا المستند ورقم الهوية مسجل مسبقاً لضيف آخر (This document type and verification number is already registered to another guest)',
        );
      }
    }

    final updated = guest.copyWith(
      fullName: guest.fullName.trim(),
      phone: guest.phone?.trim(),
      email: guest.email?.trim(),
      nationality: guest.nationality?.trim(),
      documentType: guest.documentType?.trim(),
      documentNumber: guest.documentNumber?.trim(),
      dateOfBirth: guest.dateOfBirth?.trim(),
      address: guest.address?.trim(),
      notes: guest.notes?.trim(),
      updatedAt: DateTime.now(),
    );

    final oldGuest = await _repository.getGuestById(updated.id!);
    final oldMap = oldGuest != null ? GuestModel.toMap(oldGuest) : null;

    await _repository.updateGuest(updated, userId);

    // Log Audit Event
    await _auditService.log(
      userId: userId,
      entityType: 'Guest',
      entityId: updated.id!,
      action: 'Update Guest',
      description: 'حدّث بيانات الضيف: ${updated.fullName} (Updated guest: ${updated.fullName})',
      oldValues: oldMap,
      newValues: GuestModel.toMap(updated),
    );
  }
}
