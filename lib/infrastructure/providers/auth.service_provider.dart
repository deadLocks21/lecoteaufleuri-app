import 'package:lecoteaufleuri/core/application/services/auth_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/logout.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/refresh_session.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/request_otp.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/restore_session.usecase.dart';
import 'package:lecoteaufleuri/core/application/usecases/verify_otp.usecase.dart';
import 'package:lecoteaufleuri/infrastructure/providers/auth.repository_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/session.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth.service_provider.g.dart';

@Riverpod(keepAlive: true)
AuthApplicationService authService(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  final sessions = ref.watch(sessionRepositoryProvider);
  return AuthApplicationService(
    requestOtp: RequestOtpUseCase(auth),
    verifyOtp: VerifyOtpUseCase(auth, sessions),
    restoreSession: RestoreSessionUseCase(sessions),
    refreshSession: RefreshSessionUseCase(auth, sessions),
    logout: LogoutUseCase(sessions),
  );
}
