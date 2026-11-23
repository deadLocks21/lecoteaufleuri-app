// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_feed.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
/// régénérer. Libéré avec la feuille qui l'affiche.

@ProviderFor(CalendarFeedController)
final calendarFeedControllerProvider = CalendarFeedControllerFamily._();

/// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
/// régénérer. Libéré avec la feuille qui l'affiche.
final class CalendarFeedControllerProvider
    extends $AsyncNotifierProvider<CalendarFeedController, CalendarFeedDto> {
  /// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
  /// régénérer. Libéré avec la feuille qui l'affiche.
  CalendarFeedControllerProvider._({
    required CalendarFeedControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'calendarFeedControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarFeedControllerHash();

  @override
  String toString() {
    return r'calendarFeedControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarFeedController create() => CalendarFeedController();

  @override
  bool operator ==(Object other) {
    return other is CalendarFeedControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarFeedControllerHash() =>
    r'b0cf37167ad254df4edddfb9c50ef5aec9fff28f';

/// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
/// régénérer. Libéré avec la feuille qui l'affiche.

final class CalendarFeedControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarFeedController,
          AsyncValue<CalendarFeedDto>,
          CalendarFeedDto,
          FutureOr<CalendarFeedDto>,
          String
        > {
  CalendarFeedControllerFamily._()
    : super(
        retry: null,
        name: r'calendarFeedControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
  /// régénérer. Libéré avec la feuille qui l'affiche.

  CalendarFeedControllerProvider call(String stayId) =>
      CalendarFeedControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'calendarFeedControllerProvider';
}

/// Le lien d'abonnement du compte au calendrier d'un séjour, et de quoi le
/// régénérer. Libéré avec la feuille qui l'affiche.

abstract class _$CalendarFeedController
    extends $AsyncNotifier<CalendarFeedDto> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<CalendarFeedDto> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CalendarFeedDto>, CalendarFeedDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CalendarFeedDto>, CalendarFeedDto>,
              AsyncValue<CalendarFeedDto>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
