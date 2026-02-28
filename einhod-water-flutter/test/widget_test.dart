// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einhod_water/main.dart';
import 'package:einhod_water/core/services/storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  testWidgets('App basic smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EinhodWaterApp()));
    await tester.pumpAndSettle();

    // Verify that the login screen is shown.
    expect(find.text('Einhod Pure Water'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
