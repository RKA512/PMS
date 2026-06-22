/// Why the file exists:
/// Defines the life status of a User/Account member in the system.
/// Implements [Domain Model User] and [Project Structure Enums].
library;

enum UserStatus {
  active,
  disabled,
  archived;

  String toJson() => name;

  static UserStatus fromJson(String value) {
    return UserStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'نشط (Active)';
      case UserStatus.disabled:
        return 'معطل (Disabled)';
      case UserStatus.archived:
        return 'مؤرشف (Archived)';
    }
  }
}
