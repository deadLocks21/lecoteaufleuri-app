import 'package:lecoteaufleuri/core/application/dtos/session.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/otp_code.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/core/domain/services/session.repository.dart';

/// Échange le code reçu contre une session, et la persiste pour les lancements
/// suivants.
///
/// Lève une `AuthException` en cas d'échec (`invalidOtp`, `otpExpired`…).
class VerifyOtpUseCase {
  final AuthRepository _auth;
  final SessionRepository _sessions;

  const VerifyOtpUseCase(this._auth, this._sessions);

  Future<SessionDto> execute({
    required String phoneNumber,
    required String rawCode,
  }) async {
    final session = await _auth.verifyOtp(
      PhoneNumber.parse(phoneNumber),
      OtpCode.parse(rawCode),
    );
    await _sessions.write(session);
    return SessionDto.fromDomain(session);
  }
}
