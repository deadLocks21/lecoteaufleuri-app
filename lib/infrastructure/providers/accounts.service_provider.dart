import 'package:lecoteaufleuri/core/application/services/accounts_application.service.dart';
import 'package:lecoteaufleuri/core/application/usecases/accounts.usecases.dart';
import 'package:lecoteaufleuri/infrastructure/providers/account.repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts.service_provider.g.dart';

@Riverpod(keepAlive: true)
AccountsApplicationService accountsService(Ref ref) {
  final accounts = ref.watch(accountRepositoryProvider);
  return AccountsApplicationService(
    list: ListAccountsUseCase(accounts),
    save: SaveAccountUseCase(accounts),
    delete: DeleteAccountUseCase(accounts),
    setAdmin: SetAccountAdminUseCase(accounts),
    revokeSessions: RevokeAccountSessionsUseCase(accounts),
  );
}
