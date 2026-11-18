import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/session.dart';
import 'package:lecoteaufleuri/core/domain/model/user.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';

/// Connexion de démo dont `GET /api/me` rend [current] : un test peut ainsi
/// changer les droits du compte « côté serveur ».
class FakeAuthRepository implements AuthRepository {
  final _inner = InMemoryAuthRepository();
  User current;

  FakeAuthRepository(this.current);

  @override
  Future<DateTime> requestOtp(PhoneNumber phone) => _inner.requestOtp(phone);

  @override
  Future<Session> verifyOtp(PhoneNumber phone, OtpCode code) =>
      _inner.verifyOtp(phone, code);

  @override
  Future<User> currentUser() async => current;
}
