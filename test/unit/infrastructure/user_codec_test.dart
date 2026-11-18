import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/infrastructure/auth/user.codec.dart';

void main() {
  const json = {
    'id': '0a5c0000-0000-4000-8000-0000000000ff',
    'phone_number': '+33612345678',
    'first_name': 'Camille',
    'last_name': 'Martin',
    'is_admin': true,
  };

  test('lit le statut d\'admin, et le réécrit', () {
    final user = UserCodec.fromJson(json);

    expect(user.isAdmin, isTrue);
    expect(UserCodec.toJson(user), json);
  });

  test('une session enregistrée avant is_admin n\'est pas admin', () {
    expect(UserCodec.fromJson({...json}..remove('is_admin')).isAdmin, isFalse);
  });

  test('refuse un compte mal formé', () {
    expect(
      () => UserCodec.fromJson({...json, 'is_admin': 'oui'}),
      throwsFormatException,
    );
    expect(
      () => UserCodec.fromJson({...json, 'id': ''}),
      throwsFormatException,
    );
    expect(() => UserCodec.fromJson(null), throwsFormatException);
  });
}
