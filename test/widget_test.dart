import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redcloud_android/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
    await tester.pumpWidget(const MyApp(
      initialLang: 'fa',
      initialDarkMode: true,
      isFirstRun: false,
    ));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
