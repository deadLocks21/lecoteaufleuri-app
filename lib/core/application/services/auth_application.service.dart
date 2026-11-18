import 'package:lecoteaufleuri/core/application/usecases/logout.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/refresh_session.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/request_otp.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/restore_session.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/verify_otp.usecase.dart';

/// Les cas d'usage de la connexion, regroupés pour le contrôleur de session.
class AuthApplicationService {
  final RequestOtpUseCase requestOtp;
  final VerifyOtpUseCase verifyOtp;
  final RestoreSessionUseCase restoreSession;
  final RefreshSessionUseCase refreshSession;
  final LogoutUseCase logout;

  const AuthApplicationService({
    required this.requestOtp,
    required this.verifyOtp,
    required this.restoreSession,
    required this.refreshSession,
    required this.logout,
  });
}
