/// Why this file exists:
/// Standard Domain Entity for Property Type (e.g. Hotel, Apartments, Resort, Guest House).
/// Implements [Domain Model Property] classifications.
library;

class PropertyType {
  final int id;
  final String name;
  final String? description;

  const PropertyType({
    required this.id,
    required this.name,
    this.description,
  });
}
