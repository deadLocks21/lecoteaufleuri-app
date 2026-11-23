// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_calendar.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le calendrier d'un séjour, et ce que la direction y fait : placer,
/// modifier, supprimer un événement ; modifier, annuler ou rétablir une
/// seule occurrence. Chaque action rend null, ou la raison de l'échec.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).

@ProviderFor(StayCalendarController)
final stayCalendarControllerProvider = StayCalendarControllerFamily._();

/// Le calendrier d'un séjour, et ce que la direction y fait : placer,
/// modifier, supprimer un événement ; modifier, annuler ou rétablir une
/// seule occurrence. Chaque action rend null, ou la raison de l'échec.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
final class StayCalendarControllerProvider
    extends $AsyncNotifierProvider<StayCalendarController, StayCalendarDto> {
  /// Le calendrier d'un séjour, et ce que la direction y fait : placer,
  /// modifier, supprimer un événement ; modifier, annuler ou rétablir une
  /// seule occurrence. Chaque action rend null, ou la raison de l'échec.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).
  StayCalendarControllerProvider._({
    required StayCalendarControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stayCalendarControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stayCalendarControllerHash();

  @override
  String toString() {
    return r'stayCalendarControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  StayCalendarController create() => StayCalendarController();

  @override
  bool operator ==(Object other) {
    return other is StayCalendarControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stayCalendarControllerHash() =>
    r'eb27be59f30da4fac9967c2f0ddec706136dc945';

/// Le calendrier d'un séjour, et ce que la direction y fait : placer,
/// modifier, supprimer un événement ; modifier, annuler ou rétablir une
/// seule occurrence. Chaque action rend null, ou la raison de l'échec.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).

final class StayCalendarControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          StayCalendarController,
          AsyncValue<StayCalendarDto>,
          StayCalendarDto,
          FutureOr<StayCalendarDto>,
          String
        > {
  StayCalendarControllerFamily._()
    : super(
        retry: null,
        name: r'stayCalendarControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le calendrier d'un séjour, et ce que la direction y fait : placer,
  /// modifier, supprimer un événement ; modifier, annuler ou rétablir une
  /// seule occurrence. Chaque action rend null, ou la raison de l'échec.
  ///
  /// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).

  StayCalendarControllerProvider call(String stayId) =>
      StayCalendarControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'stayCalendarControllerProvider';
}

/// Le calendrier d'un séjour, et ce que la direction y fait : placer,
/// modifier, supprimer un événement ; modifier, annuler ou rétablir une
/// seule occurrence. Chaque action rend null, ou la raison de l'échec.
///
/// Libéré dès que les écrans qui l'affichent se ferment (pas de `keepAlive`).

abstract class _$StayCalendarController
    extends $AsyncNotifier<StayCalendarDto> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<StayCalendarDto> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StayCalendarDto>, StayCalendarDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StayCalendarDto>, StayCalendarDto>,
              AsyncValue<StayCalendarDto>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
