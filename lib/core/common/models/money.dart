/// Why the file exists:
/// Standard class for precise monetary calculations in the Property Management System.
/// Implements [Financial Rules FR-101 (derived metrics computed from ledger records only)] and robust typing.
/// Prevents standard float/double precision aggregation issues by encapsulating fractional math.
library;

import 'package:flutter/foundation.dart';

@immutable
class Money {
  /// Amount represented in the minor unit of currency (e.g. Halalas or Cents).
  /// For instance, 100 minor units represent 1.00 base unit of property currency.
  final int minorUnits;
  
  const Money(this.minorUnits);

  factory Money.fromDouble(double amount) {
    return Money((amount * 100).round());
  }

  factory Money.zero() => const Money(0);

  double get asDouble => minorUnits / 100.0;

  Money operator +(Money other) {
    return Money(minorUnits + other.minorUnits);
  }

  Money operator -(Money other) {
    return Money(minorUnits - other.minorUnits);
  }

  Money operator *(double multiplier) {
    return Money((minorUnits * multiplier).round());
  }

  bool operator >(Money other) => minorUnits > other.minorUnits;
  bool operator <(Money other) => minorUnits < other.minorUnits;
  bool operator >=(Money other) => minorUnits >= other.minorUnits;
  bool operator <=(Money other) => minorUnits <= other.minorUnits;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Money && other.minorUnits == minorUnits;
  }

  @override
  int get hashCode => minorUnits.hashCode;

  /// Formatted string with currency symbol.
  String format(String currencySymbol) {
    final doubleVal = asDouble;
    return '${doubleVal.toStringAsFixed(2)} $currencySymbol';
  }

  @override
  String toString() => asDouble.toStringAsFixed(2);
}
