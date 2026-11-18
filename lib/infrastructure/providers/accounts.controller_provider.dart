import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/user.dto.dart';
import 'package:lecoteaufleuri/core/application/services/accounts_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/accounts.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'accounts.controller_provider.g.dart';

/// La liste des comptes de l'écran d'administration, et ce qu'on peut en faire.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`) : les numéros des
/// comptes ne restent pas en mémoire, déconnexion comprise.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AccountErrorCode] que
/// l'écran traduit en message ; la liste est relue après chaque action.
@riverpod
class AccountsController extends _$AccountsController {
  AccountsApplicationService get _service => ref.read(accountsServiceProvider);

  @override
  Future<List<UserDto>> build() =>
      ref.watch(accountsServiceProvider).list.execute();

  Future<(UserDto?, AccountErrorCode?)> save({
    String? id,
    required String rawPhone,
    required String firstName,
    required String lastName,
  }) => _run(
    () => _service.save.execute(
      id: id,
      rawPhone: rawPhone,
      firstName: firstName,
      lastName: lastName,
    ),
  );

  Future<(UserDto?, AccountErrorCode?)> setAdmin(
    String id, {
    required bool admin,
  }) => _run(() => _service.setAdmin.execute(id, admin: admin));

  Future<AccountErrorCode?> delete(String id) async =>
      (await _run(() => _service.delete.execute(id))).$2;

  Future<AccountErrorCode?> revokeSessions(String id) async =>
      (await _run(() => _service.revokeSessions.execute(id))).$2;

  Future<(T?, AccountErrorCode?)> _run<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      if (ref.mounted) ref.invalidateSelf();
      return (result, null);
    } on AccountException catch (e) {
      // Compte disparu entre-temps : la liste ne doit plus le montrer.
      if (e.code == AccountErrorCode.notFound && ref.mounted) {
        ref.invalidateSelf();
      }
      return (null, e.code);
    } catch (e, stack) {
      debugPrint('comptes : échec inattendu : $e\n$stack');
      return (null, AccountErrorCode.unknown);
    }
  }
}
