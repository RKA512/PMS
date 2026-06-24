/// Why the file exists:
/// Defines the operational and maintenance statuses of a Unit in the PMS.
/// Implements [Domain Model Unit Status].
/// Satisfies states: Available, Reserved, Occupied, Maintenance, OutOfService, Archived.
library;

enum UnitStatus {
  available,
  reserved,
  occupied,
  maintenance,
  outOfService;

  String toJson() => name;

  static UnitStatus fromJson(String value) {
    return UnitStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UnitStatus.available,
    );
  }

  String get displayName {
    switch (this) {
      case UnitStatus.available:
        return 'متاح (Available)';
      case UnitStatus.reserved:
        return 'محجوز (Reserved)';
      case UnitStatus.occupied:
        return 'مشغول (Occupied)';
      case UnitStatus.maintenance:
        return 'صيانة (Maintenance)';
      case UnitStatus.outOfService:
        return 'خارج الخدمة (Out of Service)';
    }
  }
}
