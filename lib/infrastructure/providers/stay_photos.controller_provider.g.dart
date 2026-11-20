// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_photos.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
/// les siennes pour un animateur), et de quoi en déposer, les trier ou les
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de
/// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
/// [NewsErrorCode] que l'écran traduit.

@ProviderFor(StayPhotosController)
final stayPhotosControllerProvider = StayPhotosControllerFamily._();

/// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
/// les siennes pour un animateur), et de quoi en déposer, les trier ou les
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de
/// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
/// [NewsErrorCode] que l'écran traduit.
final class StayPhotosControllerProvider
    extends $AsyncNotifierProvider<StayPhotosController, List<StayPhotoDto>> {
  /// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
  /// les siennes pour un animateur), et de quoi en déposer, les trier ou les
  /// supprimer.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de
  /// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
  /// [NewsErrorCode] que l'écran traduit.
  StayPhotosControllerProvider._({
    required StayPhotosControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stayPhotosControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stayPhotosControllerHash();

  @override
  String toString() {
    return r'stayPhotosControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StayPhotosController create() => StayPhotosController();

  @override
  bool operator ==(Object other) {
    return other is StayPhotosControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stayPhotosControllerHash() =>
    r'fa692534f265a5c7251f4afb4e37a3d92b97104d';

/// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
/// les siennes pour un animateur), et de quoi en déposer, les trier ou les
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de
/// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
/// [NewsErrorCode] que l'écran traduit.

final class StayPhotosControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StayPhotosController,
          AsyncValue<List<StayPhotoDto>>,
          List<StayPhotoDto>,
          FutureOr<List<StayPhotoDto>>,
          String
        > {
  StayPhotosControllerFamily._()
    : super(
        retry: null,
        name: r'stayPhotosControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
  /// les siennes pour un animateur), et de quoi en déposer, les trier ou les
  /// supprimer.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de
  /// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
  /// [NewsErrorCode] que l'écran traduit.

  StayPhotosControllerProvider call(String stayId) =>
      StayPhotosControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'stayPhotosControllerProvider';
}

/// Les photos d'un séjour que le compte peut trier (toutes pour la direction,
/// les siennes pour un animateur), et de quoi en déposer, les trier ou les
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de
/// `keepAlive`). Les actions rendent `null` en cas de succès, sinon le
/// [NewsErrorCode] que l'écran traduit.

abstract class _$StayPhotosController
    extends $AsyncNotifier<List<StayPhotoDto>> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<List<StayPhotoDto>> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<StayPhotoDto>>, List<StayPhotoDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<StayPhotoDto>>, List<StayPhotoDto>>,
              AsyncValue<List<StayPhotoDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
