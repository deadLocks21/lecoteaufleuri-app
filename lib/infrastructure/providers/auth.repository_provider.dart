import 'package:lecoteaufleuri/core/domain/services/auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/dio.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/auth/in_memory.auth.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth.repository_provider.g.dart';

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, compte de démo en
/// mémoire sinon.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  if (isInMemoryMode(ref.watch(apiBaseUrlProvider))) {
    return InMemoryAuthRepository();
  }
  return DioAuthRepository(ref.watch(dioProvider));
}
