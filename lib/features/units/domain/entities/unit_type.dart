/// Why this file exists:
/// Standard Domain Entity for Unit Types.
/// Follows Clean Architecture Domain standards.
library;

class UnitType {
  final int id;
  final String name;
  final String? description;

  const UnitType({
    required this.id,
    required this.name,
    this.description,
  });
}
