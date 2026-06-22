/// Why this file exists:
/// Model representing Guest Contact mapping to and from SQLite.
library;

import '../../domain/entities/guest_contact.dart';

class GuestContactModel {
  static Map<String, dynamic> toMap(GuestContact contact) {
    return {
      if (contact.id != null) 'id': contact.id,
      if (contact.guestId != null) 'guest_id': contact.guestId,
      'contact_type': contact.contactType,
      'contact_value': contact.contactValue,
      'created_at': contact.createdAt.toIso8601String(),
    };
  }

  static GuestContact fromMap(Map<String, dynamic> map) {
    return GuestContact(
      id: map['id'] as int?,
      guestId: map['guest_id'] as int?,
      contactType: map['contact_type'] as String,
      contactValue: map['contact_value'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
