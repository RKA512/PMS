/// Why this file exists:
/// Smoke test for the main application widget [PropertyManagementSystemApp].
/// Verifies the dashboard loads successfully.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_management_system/app/app.dart';

void main() {
  testWidgets('PMS App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PropertyManagementSystemApp(),
      ),
    );

    // Verify that the app starts successfully and displays the main dashboard heading.
    expect(find.text('نظام إدارة الفنادق والعقارات الشامل'), findsOneWidget);
  });
}
