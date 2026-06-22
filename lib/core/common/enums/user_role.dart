/// Why the file exists:
/// Defines the functional roles of the system users.
/// Implements [Permissions Matrix Roles] and [Domain Model Roles].
/// Roles: Owner, Manager, Receptionist, Accountant, Housekeeping.
library;

enum UserRole {
  owner,
  manager,
  receptionist,
  accountant,
  housekeeping;

  String toJson() => name;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.receptionist,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.owner:
        return 'المالك (Owner)';
      case UserRole.manager:
        return 'المدير (Manager)';
      case UserRole.receptionist:
        return 'موظف استقبال (Receptionist)';
      case UserRole.accountant:
        return 'المحاسب (Accountant)';
      case UserRole.housekeeping:
        return 'الخدمات والصيانة (Housekeeping)';
    }
  }
}
