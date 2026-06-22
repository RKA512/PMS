import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider containing the currently authenticated User ID.
/// Returns null if no user is authenticated.
final authenticatedUserIdProvider = Provider<int?>((ref) {
  // Minimal integration point waiting for the full auth/session infrastructure.
  // In a production setup, this would listen to AuthNotifier.
  return null;
});

/// Provider containing the currently active Account ID context.
/// Returns null if no account context is active.
final activeAccountIdProvider = Provider<int?>((ref) {
  // Minimal integration point waiting for the full auth/session infrastructure.
  return null;
});
