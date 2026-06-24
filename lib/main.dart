/// Why the file exists:
/// Entry point of the production Flutter application.
/// Initializes the sqlite databases, hooks Riverpod providers, and runs the MaterialApp bootstrap.
/// Satisfies [Architecture style Clean-first] and Riverpod integration hooks.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/database/database_helper.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  
  // Initialize Database Helper locally beforehand
  try {
    await DatabaseHelper.instance.database;
  } catch (dbError) {
    // Fail-Safe: database error handles gracefully in production
    debugPrint('Database Initialization Error: $dbError');
  }

  runApp(
    const ProviderScope(
      child: PropertyManagementSystemApp(),
    ),
  );
}
