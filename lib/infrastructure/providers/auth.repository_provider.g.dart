// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, compte de démo en
/// mémoire sinon.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, compte de démo en
/// mémoire sinon.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, compte de démo en
  /// mémoire sinon.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'4551105ad63b974b5c32c7ce0ed17ea812872fa8';
