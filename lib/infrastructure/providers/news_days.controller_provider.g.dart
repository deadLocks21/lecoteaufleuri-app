// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_days.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
/// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
/// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
/// chaque photo (la pioche) et les nouvelles publiées.

@ProviderFor(NewsDaysController)
final newsDaysControllerProvider = NewsDaysControllerFamily._();

/// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
/// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
/// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
/// chaque photo (la pioche) et les nouvelles publiées.
final class NewsDaysControllerProvider
    extends $AsyncNotifierProvider<NewsDaysController, List<NewsDayDto>> {
  /// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
  /// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
  /// supprimer.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
  /// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
  /// chaque photo (la pioche) et les nouvelles publiées.
  NewsDaysControllerProvider._({
    required NewsDaysControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'newsDaysControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$newsDaysControllerHash();

  @override
  String toString() {
    return r'newsDaysControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  NewsDaysController create() => NewsDaysController();

  @override
  bool operator ==(Object other) {
    return other is NewsDaysControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$newsDaysControllerHash() =>
    r'0cdc8461e087fbdc6adabdead763edc29d9b6bcd';

/// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
/// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
/// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
/// chaque photo (la pioche) et les nouvelles publiées.

final class NewsDaysControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          NewsDaysController,
          AsyncValue<List<NewsDayDto>>,
          List<NewsDayDto>,
          FutureOr<List<NewsDayDto>>,
          String
        > {
  NewsDaysControllerFamily._()
    : super(
        retry: null,
        name: r'newsDaysControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
  /// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
  /// supprimer.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
  /// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
  /// chaque photo (la pioche) et les nouvelles publiées.

  NewsDaysControllerProvider call(String stayId) =>
      NewsDaysControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'newsDaysControllerProvider';
}

/// Les jours d'un séjour, tels que la direction les compose, et ce qu'on peut
/// y faire : créer, corriger, illustrer, publier, programmer, dépublier,
/// supprimer.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
/// Chaque action relit aussi ce qu'elle change ailleurs : le jour illustré par
/// chaque photo (la pioche) et les nouvelles publiées.

abstract class _$NewsDaysController extends $AsyncNotifier<List<NewsDayDto>> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<List<NewsDayDto>> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<NewsDayDto>>, List<NewsDayDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NewsDayDto>>, List<NewsDayDto>>,
              AsyncValue<List<NewsDayDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
