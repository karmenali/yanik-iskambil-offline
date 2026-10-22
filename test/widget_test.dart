import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yanik_offline/main.dart';
import 'package:yanik_offline/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches with OYNA button smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();

    await tester.pumpWidget(const YanikOfflineApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('OYNA'), findsOneWidget);
    expect(find.text('YANIK İSKAMBİL'), findsOneWidget);
  });
}
