import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:twinchat/di/injection.dart';
import 'package:twinchat/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Полноценные виджет-тесты добавим позже. Сейчас — только smoke:
    // убеждаемся, что DI инициализируется без падения и TwinChatApp собирается.
    SharedPreferences.setMockInitialValues(
      <String, Object>{'placeholder': true},
    );
    await configureDependencies();
  });

  testWidgets('TwinChatApp builds without crashing', (tester) async {
    await tester.pumpWidget(const app.TwinChatApp());
    // Корневой App widget может быть любым из MaterialApp/CupertinoApp;
    // главное, что сборка прошла без исключений.
    expect(find.byType(WidgetsApp), findsAny);
  });

  test('DI registers core dependencies', () {
    expect(getIt.isRegistered<FlutterSecureStorage>(), isTrue);
  });
}
