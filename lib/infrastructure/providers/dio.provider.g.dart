// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Client HTTP partagé par tous les `dio.*.repository.dart`.
///
/// Son [AuthInterceptor] pose le Bearer et, sur `401 invalid_token`, demande au
/// [SessionController] de relancer la connexion ; sur `403 forbidden`, de
/// relire les droits du compte. Le contrôleur est lu
/// paresseusement (`ref.read` dans le callback) : le résoudre à la construction
/// bouclerait (`dio → sessionController → authService → authRepository → dio`).

@ProviderFor(dio)
final dioProvider = DioProvider._();

/// Client HTTP partagé par tous les `dio.*.repository.dart`.
///
/// Son [AuthInterceptor] pose le Bearer et, sur `401 invalid_token`, demande au
/// [SessionController] de relancer la connexion ; sur `403 forbidden`, de
/// relire les droits du compte. Le contrôleur est lu
/// paresseusement (`ref.read` dans le callback) : le résoudre à la construction
/// bouclerait (`dio → sessionController → authService → authRepository → dio`).

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  /// Client HTTP partagé par tous les `dio.*.repository.dart`.
  ///
  /// Son [AuthInterceptor] pose le Bearer et, sur `401 invalid_token`, demande au
  /// [SessionController] de relancer la connexion ; sur `403 forbidden`, de
  /// relire les droits du compte. Le contrôleur est lu
  /// paresseusement (`ref.read` dans le callback) : le résoudre à la construction
  /// bouclerait (`dio → sessionController → authService → authRepository → dio`).
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'a695cca34e08d6e3c762297457af7820cbb29fcf';
