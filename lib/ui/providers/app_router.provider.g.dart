// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le routeur de l'app : l'adresse suit la [SessionState].
///
/// - Tant que la session se relit, l'app attend sur `/chargement`, puis
///   reprend l'adresse demandée (un lien vers un séjour, sur le web).
/// - Sans session, la connexion ; une session fermée referme donc tout ce qui
///   était ouvert, et ses données (providers sans `keepAlive`) avec.
/// - L'administration est réservée aux admins ; perdre ce statut ramène au
///   séjour du moment, quel que soit l'écran ouvert.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Le routeur de l'app : l'adresse suit la [SessionState].
///
/// - Tant que la session se relit, l'app attend sur `/chargement`, puis
///   reprend l'adresse demandée (un lien vers un séjour, sur le web).
/// - Sans session, la connexion ; une session fermée referme donc tout ce qui
///   était ouvert, et ses données (providers sans `keepAlive`) avec.
/// - L'administration est réservée aux admins ; perdre ce statut ramène au
///   séjour du moment, quel que soit l'écran ouvert.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Le routeur de l'app : l'adresse suit la [SessionState].
  ///
  /// - Tant que la session se relit, l'app attend sur `/chargement`, puis
  ///   reprend l'adresse demandée (un lien vers un séjour, sur le web).
  /// - Sans session, la connexion ; une session fermée referme donc tout ce qui
  ///   était ouvert, et ses données (providers sans `keepAlive`) avec.
  /// - L'administration est réservée aux admins ; perdre ce statut ramène au
  ///   séjour du moment, quel que soit l'écran ouvert.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'dbdd4511acf0a8ef01a19afd01f4383c8529688f';
