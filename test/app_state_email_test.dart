import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farm/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FFAppState.reset();
  });

  test('stores and exposes the user email in app state', () {
    final appState = FFAppState();

    appState.email = 'user@example.com';

    expect(appState.email, 'user@example.com');
  });
}
