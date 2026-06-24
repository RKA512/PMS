/// Why this file exists:
/// Use case for creating a guest. Enforces business rules and validation schemas.
library;

import 'package:uuid/uuid.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../../data/models/guest_model.dart';
import '../entities/guest.dart';
import '../entities/guest_contact.dart';
import '../repositories/guest_repository.dart';

class CreateGuest {
  final GuestRepository _repository;
  final AuditLogger _auditService;
  final _uuid = const Uuid();

  CreateGuest(this._repository, this._auditService);

  Future<int> call({
    required int accountId,
    required int userId,
    required String fullName,
    String? phone,
    String? email,
    String? nationality,
    String? documentType,
    String? documentNumber,
    String? dateOfBirth,
    String? address,
    String? notes,
    List<GuestContact> contacts = const [],
  }) async {
    // 1. Name presence validation
    if (fullName.trim().isEmpty) {
      throw const ValidationFailure(
        code: 'GUEST_NAME_EMPTY',
        message: 'اسم الضيف لا يمكن أن يكون فارغاً (Guest name cannot be empty)',
      );
    }

    // 2. Email format validation
    if (email != null && email.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(email.trim())) {
        throw const ValidationFailure(
          code: 'GUEST_EMAIL_INVALID',
          message: 'صيغة البريد الإلكتروني غير صالحة (Invalid email format)',
        );
      }
    }

    // 3. Phone format validation
    if (phone != null && phone.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{7,15}$');
      if (!phoneRegex.hasMatch(phone.trim())) {
        throw const ValidationFailure(
          code: 'GUEST_PHONE_INVALID',
          message: 'رقم الهاتف المكتوب غير صالح (Invalid phone format)',
        );
      }
    }

    // 4. Duplicate document prevention
    if (documentType != null && documentType.trim().isNotEmpty &&
        documentNumber != null && documentNumber.trim().isNotEmpty) {
      final existing = await _repository.getGuestByDocument(
        accountId,
        documentType.trim(),
        documentNumber.trim(),
      );
      if (existing != null) {
        throw const ValidationFailure(
          code: 'GUEST_DOCUMENT_DUPLICATE',
          message: 'هذا المستند ورقم الهوية مسجل مسبقاً لضيف آخر (This document type and verification number is already registered to another guest)',
        );
      }
    }

    final now = DateTime.now();
    final guest = Guest(
      uuid: _uuid.v4(),
      accountId: accountId,
      fullName: fullName.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      nationality: nationality?.trim(),
      documentType: documentType?.trim(),
      documentNumber: documentNumber?.trim(),
      dateOfBirth: dateOfBirth?.trim(),
      address: address?.trim(),
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
      contacts: contacts,
    );

    final id = await _repository.createGuest(guest, userId);

    // Log Audit Event
    await _auditService.log(
      userId: userId,
      entityType: 'Guest',
      entityId: id,
      action: 'Create Guest',
      description: 'أنشأ الضيف: ${guest.fullName} (Created guest: ${guest.fullName})',
      newValues: GuestModel.toMap(guest)..['id'] = id,
    );

    return id;
  }
}
