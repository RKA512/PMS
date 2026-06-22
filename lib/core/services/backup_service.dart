/// Why the file exists:
/// Handles creating secure, self-contained copies of the local SQLite database.
/// Implements [Application Flows Flow 34] and [Audit Policy AP-1200].
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'audit_service.dart';

class BackupService {
  static final BackupService instance = BackupService._init();

  BackupService._init();

  /// Creates a backup file of the main SQLite database at the specified destination directory.
  /// Logs a critical audit event on completion (AP-1200).
  Future<File> createBackup(String destinationFolder, int currentUserId) async {
    final dbHelper = DatabaseHelper.instance;
    // ensure database is initialized
    await dbHelper.database;
    
    final dbPath = await getDatabasesPath();
    final currentDbFile = File(join(dbPath, 'property_management_system.db'));

    if (!await currentDbFile.exists()) {
      throw const FileSystemException('قاعدة البيانات الأصلية غير موجودة (Database file not found).');
    }

    // Ensure the destination dir exists
    final dir = Directory(destinationFolder);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFileName = 'pms_backup_$timestamp.db';
    final backupFile = File(join(destinationFolder, backupFileName));

    // Safely copy the DB file
    final savedFile = await currentDbFile.copy(backupFile.path);

    // AP-1200 log
    await AuditService.instance.log(
      userId: currentUserId,
      entityType: 'system_backup',
      entityId: timestamp,
      action: 'Backup Created',
      description: 'سحب نسخة احتياطية من قاعدة البيانات بنجاح: $backupFileName',
      newValues: {
        'backup_path': savedFile.path,
        'file_size_bytes': await savedFile.length(),
      }
    );

    return savedFile;
  }
}
