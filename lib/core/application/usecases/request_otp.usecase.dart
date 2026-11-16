import 'package:lecoteaufleuri/core/application/dtos/otp_request.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';

/// Normalise le numéro saisi et fait envoyer un code par SMS.
///
/// Lève une `AuthException` en cas d'échec (`invalidPhone` avant tout appel
/// réseau, `accountNotFound` pour un numéro sans compte…).
class RequestOtpUseCase {
  final AuthRepository _auth;

  const RequestOtpUseCase(this._auth);

  Future<OtpRequestDto> execute(String rawPhone) async {
    final phone = PhoneNumber.parse(rawPhone);
    final expiresAt = await _auth.requestOtp(phone);
    return OtpRequestDto(phoneNumber: phone.e164, expiresAt: expiresAt);
  }
}
