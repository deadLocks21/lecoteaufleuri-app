// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts.service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(accountsService)
final accountsServiceProvider = AccountsServiceProvider._();

final class AccountsServiceProvider
    extends
        $FunctionalProvider<
          AccountsApplicationService,
          AccountsApplicationService,
          AccountsApplicationService
        >
    with $Provider<AccountsApplicationService> {
  AccountsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsServiceHash();

  @$internal
  @override
  $ProviderElement<AccountsApplicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountsApplicationService create(Ref ref) {
    return accountsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountsApplicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountsApplicationService>(value),
    );
  }
}

String _$accountsServiceHash() => r'9742935dd70acb26a4564990bf4c7d8b6d8f5d90';
