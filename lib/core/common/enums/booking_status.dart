/// Why the file exists:
/// Defines the official operational states for a Booking in the Property Management System.
/// Implements [Booking Rules BR-302] and [Domain Model Booking Status].
/// Satisfies the Booking lifecycle states: Reserved, CheckedIn, CheckedOut, Cancelled, NoShow.
library;

enum BookingStatus {
  reserved,
  checkedIn,
  checkedOut,
  cancelled,
  noShow;

  String toJson() => name;

  static BookingStatus fromJson(String value) {
    return BookingStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BookingStatus.reserved,
    );
  }

  String get displayName {
    switch (this) {
      case BookingStatus.reserved:
        return 'مؤكد (Reserved)';
      case BookingStatus.checkedIn:
        return 'تم الدخول (Checked In)';
      case BookingStatus.checkedOut:
        return 'تم الخروج (Checked Out)';
      case BookingStatus.cancelled:
        return 'ملغي (Cancelled)';
      case BookingStatus.noShow:
        return 'عدم حضور (No Show)';
    }
  }
}
