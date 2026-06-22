/// Why the file exists:
/// Represents the fundamental User of the application.
/// Implements [Domain Model User] and [Business Rules User section 3].
library;

import '../enums/user_role.dart';
import '../enums/user_status.dart';

class AppUser {
  final int? id;
  final String uuid;
  final int accountId;
  final UserRole role;
  final String name;
  final String email;
  final String passwordHash;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const AppUser({
    this.id,
    required this.uuid,
    required this.accountId,
    required this.role,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'uuid': uuid,
      'account_id': accountId,
      'role_id': role.index + 1, // mapped to id of role table
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      accountId: map['account_id'] as int,
      role: UserRole.values[(map['role_id'] as int) - 1],
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      status: UserStatus.fromJson(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
