// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stays.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// La liste des séjours de l'écran d'administration, et leur création.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`), comme les comptes :
/// rien ne survit à une déconnexion ou à un statut d'admin retiré.
///
/// [create] rend le séjour créé, ou l'[StayErrorCode] que l'écran traduit en
/// message ; la liste est relue après une création.

@ProviderFor(StaysController)
final staysControllerProvider = StaysControllerProvider._();

/// La liste des séjours de l'écran d'administration, et leur création.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`), comme les comptes :
/// rien ne survit à une déconnexion ou à un statut d'admin retiré.
///
/// [create] rend le séjour créé, ou l'[StayErrorCode] que l'écran traduit en
/// message ; la liste est relue après une création.
final class StaysControllerProvider
    extends $AsyncNotifierProvider<StaysController, List<StayDto>> {
  /// La liste des séjours de l'écran d'administration, et leur création.
  ///
  /// Libérée dès que l'écran se ferme (pas de `keepAlive`), comme les comptes :
  /// rien ne survit à une déconnexion ou à un statut d'admin retiré.
  ///
  /// [create] rend le séjour créé, ou l'[StayErrorCode] que l'écran traduit en
  /// message ; la liste est relue après une création.
  StaysControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staysControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staysControllerHash();

  @$internal
  @override
  StaysController create() => StaysController();
}

String _$staysControllerHash() => r'cd2ff97dcc20028dc7b2cd859f719fdc7cc0590e';

/// La liste des séjours de l'écran d'administration, et leur création.
///
/// Libérée dès que l'écran se ferme (pas de `keepAlive`), comme les comptes :
/// rien ne survit à une déconnexion ou à un statut d'admin retiré.
///
/// [create] rend le séjour créé, ou l'[StayErrorCode] que l'écran traduit en
/// message ; la liste est relue après une création.

abstract class _$StaysController extends $AsyncNotifier<List<StayDto>> {
  FutureOr<List<StayDto>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<StayDto>>, List<StayDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StayDto>>, List<StayDto>>,
              AsyncValue<List<StayDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
