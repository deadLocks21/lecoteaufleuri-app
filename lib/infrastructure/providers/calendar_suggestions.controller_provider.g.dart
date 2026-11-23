// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_suggestions.controller_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
/// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
/// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
/// calendrier, qu'elle vient de changer.

@ProviderFor(CalendarSuggestionsController)
final calendarSuggestionsControllerProvider =
    CalendarSuggestionsControllerFamily._();

/// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
/// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
/// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
/// calendrier, qu'elle vient de changer.
final class CalendarSuggestionsControllerProvider
    extends
        $AsyncNotifierProvider<
          CalendarSuggestionsController,
          List<CalendarSuggestionDto>
        > {
  /// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
  /// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
  /// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
  /// calendrier, qu'elle vient de changer.
  CalendarSuggestionsControllerProvider._({
    required CalendarSuggestionsControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'calendarSuggestionsControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarSuggestionsControllerHash();

  @override
  String toString() {
    return r'calendarSuggestionsControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarSuggestionsController create() => CalendarSuggestionsController();

  @override
  bool operator ==(Object other) {
    return other is CalendarSuggestionsControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarSuggestionsControllerHash() =>
    r'aec68ace941e4dce60ea2108881ea2a118218703';

/// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
/// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
/// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
/// calendrier, qu'elle vient de changer.

final class CalendarSuggestionsControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarSuggestionsController,
          AsyncValue<List<CalendarSuggestionDto>>,
          List<CalendarSuggestionDto>,
          FutureOr<List<CalendarSuggestionDto>>,
          String
        > {
  CalendarSuggestionsControllerFamily._()
    : super(
        retry: null,
        name: r'calendarSuggestionsControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
  /// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
  /// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
  /// calendrier, qu'elle vient de changer.

  CalendarSuggestionsControllerProvider call(String stayId) =>
      CalendarSuggestionsControllerProvider._(argument: stayId, from: this);

  @override
  String toString() => r'calendarSuggestionsControllerProvider';
}

/// Les suggestions d'un séjour (toutes pour la direction, les siennes pour un
/// animateur), et ce qu'on en fait : proposer, retirer, accepter, refuser.
/// Chaque action rend null, ou la raison de l'échec ; accepter relit aussi le
/// calendrier, qu'elle vient de changer.

abstract class _$CalendarSuggestionsController
    extends $AsyncNotifier<List<CalendarSuggestionDto>> {
  late final _$args = ref.$arg as String;
  String get stayId => _$args;

  FutureOr<List<CalendarSuggestionDto>> build(String stayId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<CalendarSuggestionDto>>,
              List<CalendarSuggestionDto>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<CalendarSuggestionDto>>,
                List<CalendarSuggestionDto>
              >,
              AsyncValue<List<CalendarSuggestionDto>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
