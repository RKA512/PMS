/// Why this file exists:
/// Model representing Guest mapping to and from SQLite.
library;

import '../../domain/entities/guest.dart';

class GuestModel {
  static Map<String, dynamic> toMap(Guest guest) {
    return {
      if (guest.id != null) 'id': guest.id,
      'uuid': guest.uuid,
      'account_id': guest.accountId,
      'full_name': guest.fullName,
      'phone': guest.phone,
      'email': guest.email,
      'nationality': guest.nationality,
      'document_type': guest.documentType,
      'document_number': guest.documentNumber,
      'date_of_birth': guest.dateOfBirth,
      'address': guest.address,
      'notes': guest.notes,
      'created_at': guest.createdAt.toIso8601String(),
      'updated_at': guest.updatedAt.toIso8601String(),
      'deleted_at': guest.deletedAt?.toIso8601String(),
    };
  }

  static Guest fromMap(Map<String, dynamic> map, {List<dynamic> contacts = const []}) {
    return Guest(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      accountId: map['account_id'] as int,
      fullName: map['full_name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      nationality: map['nationality'] as String?,
      documentType: map['document_type'] as String?,
      documentNumber: map['document_number'] as String?,
      dateOfBirth: map['date_of_birth'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
