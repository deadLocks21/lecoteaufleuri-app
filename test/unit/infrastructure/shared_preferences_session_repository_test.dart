import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/infrastructure/session/shared_preferences.session.repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fixtures.dart';

void main() {
  final session = sessionExpiringAt(DateTime.utc(2026, 1, 31, 12));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('survit à un redémarrage de l\'app', () async {
    await SharedPreferencesSessionRepository().write(session);

    expect(await SharedPreferencesSessionRepository().read(), session);
  });

  test('oublie la session à la déconnexion', () async {
    final repository = SharedPreferencesSessionRepository();
    await repository.write(session);

    await repository.clear();

    expect(await repository.read(), isNull);
    expect(await SharedPreferencesSessionRepository().read(), isNull);
  });

  test('une valeur illisible vaut « pas de session »', () async {
    SharedPreferences.setMockInitialValues({
      'lecoteaufleuri.session': '{"token": 42}',
    });

    expect(await SharedPreferencesSessionRepository().read(), isNull);
  });
}
