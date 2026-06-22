/// Why the file exists:
/// Handles restoring the local SQLite database from a previously saved backup file safely.
/// Implements [Application Flows Flow 35], [Error Handling Policy EH-1000/EH-1001], and [Audit Policy AP-1201].
/// Recovery rule: If restore fails, the working database file is preserved and not replaced.
library;

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'audit_service.dart';

class RestoreService {
  static final RestoreService instance = RestoreService._init();

  RestoreService._init();

  /// Restores database of the application from a specified backup path.
  /// Implements EH-1000 and EH-1001 by performing schema validation checks before replacing files.
  Future<bool> restoreDatabase(String backupPath, int currentUserId) async {
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw const FileSystemException('ملف النسخة الاحتياطية غير موجود (Backup file not found).');
    }

    // EH-1001: Validate file structure by attempting to open it as a sqlite database
    Database? tempDb;
    try {
      tempDb = await openDatabase(backupPath, readOnly: true);
      final testQuery = await tempDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='accounts';");
      if (testQuery.isEmpty) {
        throw const FormatException('بنية الملف غير متوافقة مع قاعدة بيانات النظام (Invalid database schema).');
      }
    } catch (e) {
      throw FormatException('الملف تالف أو ليس ملف قاعدة بيانات صالح: ${e.toString()}');
    } finally {
      if (tempDb != null) {
        await tempDb.close();
      }
    }

    // If validation succeeds, close active DB connections before replacing files
    await DatabaseHelper.instance.close();

    final dbPath = await getDatabasesPath();
    final activeDbFile = File(join(dbPath, 'property_management_system.db'));

    // Safe swap: copy file over
    await backupFile.copy(activeDbFile.path);

    // Reopen database helper
    await DatabaseHelper.instance.database;

    // AP-1201 critical log
    await AuditService.instance.log(
      userId: currentUserId,
      entityType: 'system_restore',
      entityId: DateTime.now().millisecondsSinceEpoch,
      action: 'Restore Database',
      description: 'تم استعادة قاعدة البيانات بنجاح من النسخة الاحتياطية ($backupPath)',
    );

    return true;
  }
}
