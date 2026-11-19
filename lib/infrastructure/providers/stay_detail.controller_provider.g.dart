// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_detail.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
/// adjoints).
///
/// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
/// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
/// séjour rendu par l'API remplace l'état.

@ProviderFor(StayDetailController)
final stayDetailControllerProvider = StayDetailControllerFamily._();

/// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
/// adjoints).
///
/// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
/// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
/// séjour rendu par l'API remplace l'état.
final class StayDetailControllerProvider
    extends $AsyncNotifierProvider<StayDetailController, StayDetailDto> {
  /// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
  /// adjoints).
  ///
  /// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
  /// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
  /// séjour rendu par l'API remplace l'état.
  StayDetailControllerProvider._({
    required StayDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stayDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stayDetailControllerHash();

  @override
  String toString() {
    return r'stayDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StayDetailController create() => StayDetailController();

  @override
  bool operator ==(Object other) {
    return other is StayDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stayDetailControllerHash() =>
    r'299aa78b09593f2090e86d8d15451578d601d62d';

/// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
/// adjoints).
///
/// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
/// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
/// séjour rendu par l'API remplace l'état.

final class StayDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StayDetailController,
          AsyncValue<StayDetailDto>,
          StayDetailDto,
          FutureOr<StayDetailDto>,
          String
        > {
  StayDetailControllerFamily._()
    : super(
        retry: null,
        name: r'stayDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
  /// adjoints).
  ///
  /// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
  /// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
  /// séjour rendu par l'API remplace l'état.

  StayDetailControllerProvider call(String stayId) =>
      StayDetailControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'stayDetailControllerProvider';
}

/// Un séjour et sa direction, et ce qu'on peut y changer (directeur,
/// adjoints).
///
/// Libéré dès que l'écran se ferme (pas de `keepAlive`). Les actions rendent
/// `null` en cas de succès, sinon l'[StayErrorCode] que l'écran traduit ; le
/// séjour rendu par l'API remplace l'état.

abstract class _$StayDetailController extends $AsyncNotifier<StayDetailDto> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<StayDetailDto> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StayDetailDto>, StayDetailDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StayDetailDto>, StayDetailDto>,
              AsyncValue<StayDetailDto>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
