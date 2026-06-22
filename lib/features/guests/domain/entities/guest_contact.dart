/// Why this file exists:
/// Standard Domain Entity for Guest Contacts.
/// Implements [Domain Model Guest Contact] and isolates layout/presentation.
library;

class GuestContact {
  final int? id;
  final int? guestId;
  final String contactType;
  final String contactValue;
  final DateTime createdAt;

  const GuestContact({
    this.id,
    this.guestId,
    required this.contactType,
    required this.contactValue,
    required this.createdAt,
  });

  GuestContact copyWith({
    int? id,
    int? guestId,
    String? contactType,
    String? contactValue,
    DateTime? createdAt,
  }) {
    return GuestContact(
      id: id ?? this.id,
      guestId: guestId ?? this.guestId,
      contactType: contactType ?? this.contactType,
      contactValue: contactValue ?? this.contactValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
