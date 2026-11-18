// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La liste des comptes de l'écran d'administration, et ce qu'on peut en faire.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`) : les numéros des
/// comptes ne restent pas en mémoire, déconnexion comprise.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AccountErrorCode] que
/// l'écran traduit en message ; la liste est relue après chaque action.

@ProviderFor(AccountsController)
final accountsControllerProvider = AccountsControllerProvider._();

/// La liste des comptes de l'écran d'administration, et ce qu'on peut en faire.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`) : les numéros des
/// comptes ne restent pas en mémoire, déconnexion comprise.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AccountErrorCode] que
/// l'écran traduit en message ; la liste est relue après chaque action.
final class AccountsControllerProvider
    extends $AsyncNotifierProvider<AccountsController, List<UserDto>> {
  /// La liste des comptes de l'écran d'administration, et ce qu'on peut en faire.
  ///
  /// Libérée dès que l'écran se ferme (pas de `keepAlive`) : les numéros des
  /// comptes ne restent pas en mémoire, déconnexion comprise.
  ///
  /// Les actions rendent `null` en cas de succès, sinon l'[AccountErrorCode] que
  /// l'écran traduit en message ; la liste est relue après chaque action.
  AccountsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsControllerHash();

  @$internal
  @override
  AccountsController create() => AccountsController();
}

String _$accountsControllerHash() =>
    r'fa961c93688fbf556867699e453619bd97ae1002';

/// La liste des comptes de l'écran d'administration, et ce qu'on peut en faire.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`) : les numéros des
/// comptes ne restent pas en mémoire, déconnexion comprise.
///
/// Les actions rendent `null` en cas de succès, sinon l'[AccountErrorCode] que
/// l'écran traduit en message ; la liste est relue après chaque action.

abstract class _$AccountsController extends $AsyncNotifier<List<UserDto>> {
  FutureOr<List<UserDto>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<UserDto>>, List<UserDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UserDto>>, List<UserDto>>,
              AsyncValue<List<UserDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
