/// Why this file exists:
/// Standard Domain Entity for Guest.
/// Implements [Domain Model Guest] and satisfies [Architecture Layer Domain Entities are independent of Flutter].
library;

import 'guest_contact.dart';

class Guest {
  final int? id;
  final String uuid;
  final int accountId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? nationality;
  final String? documentType;
  final String? documentNumber;
  final String? dateOfBirth;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<GuestContact> contacts;

  const Guest({
    this.id,
    required this.uuid,
    required this.accountId,
    required this.fullName,
    this.phone,
    this.email,
    this.nationality,
    this.documentType,
    this.documentNumber,
    this.dateOfBirth,
    this.address,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.contacts = const [],
  });

  Guest copyWith({
    int? id,
    String? uuid,
    int? accountId,
    String? fullName,
    String? phone,
    String? email,
    String? nationality,
    String? documentType,
    String? documentNumber,
    String? dateOfBirth,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<GuestContact>? contacts,
  }) {
    return Guest(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      accountId: accountId ?? this.accountId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      nationality: nationality ?? this.nationality,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      contacts: contacts ?? this.contacts,
    );
  }
}
