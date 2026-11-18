import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';

/// Connexion factice, sans backend (dev, web, tests) : seul le compte de démo
/// existe, et son code est toujours `000000`. Tout autre numéro est refusé
/// comme un compte inconnu, exactement comme le ferait l'API.
///
/// Le compte de démo est admin, pour qu'on puisse essayer l'administration
/// des comptes sans serveur.
class InMemoryAuthRepository implements AuthRepository {
  /// `06 12 34 56 78`.
  static const demoPhoneNumber = '+33612345678';
  static const demoCode = '000000';

  static final demoUser = User(
    id: '0a5c0000-0000-4000-8000-0000000000ff',
    phoneNumber: demoPhoneNumber,
    firstName: 'Camille',
    lastName: 'Démo',
    isAdmin: true,
  );

  final DateTime Function() _now;

  InMemoryAuthRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Future<DateTime> requestOtp(PhoneNumber phone) async {
    _requireDemoAccount(phone);
    return _now().add(const Duration(minutes: 5));
  }

  @override
  Future<Session> verifyOtp(PhoneNumber phone, OtpCode code) async {
    _requireDemoAccount(phone);
    if (code.value != demoCode) {
      throw const AuthException(AuthErrorCode.invalidOtp);
    }
    return Session(
      token: 'in-memory-token',
      expiresAt: _now().add(const Duration(days: 30)),
      user: demoUser,
    );
  }

  @override
  Future<User> currentUser() async => demoUser;

  void _requireDemoAccount(PhoneNumber phone) {
    if (phone.e164 != demoPhoneNumber) {
      throw const AuthException(AuthErrorCode.accountNotFound);
    }
  }
}
