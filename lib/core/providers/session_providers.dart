import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider containing the currently authenticated User ID.
/// Returns null if no user is authenticated.
final authenticatedUserIdProvider = StateProvider<int?>((ref) {
  // Bootstrap with default seeded user ID = 1 (System Administrator)
  return 1;
});

/// Provider containing the currently active Account ID context.
/// Returns null if no account context is active.
final activeAccountIdProvider = StateProvider<int?>((ref) {
  // Bootstrap with default seeded account ID = 1 (System Default Account)
  return 1;
});
