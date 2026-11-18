import 'package:lecoteaufleuri/core/domain/services/account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/dio.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/accounts/in_memory.account.repository.dart';
import 'package:lecoteaufleuri/infrastructure/providers/api_base_url.provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/dio.provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account.repository_provider.g.dart';

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, comptes de démo en
/// mémoire sinon.
@Riverpod(keepAlive: true)
AccountRepository accountRepository(Ref ref) {
  if (isInMemoryMode(ref.watch(apiBaseUrlProvider))) {
    return InMemoryAccountRepository();
  }
  return DioAccountRepository(ref.watch(dioProvider));
}
