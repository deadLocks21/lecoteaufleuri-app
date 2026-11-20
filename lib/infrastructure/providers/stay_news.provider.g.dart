// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay_news.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
/// liront les familles. Libéré avec l'écran qui l'affiche.

@ProviderFor(stayNews)
final stayNewsProvider = StayNewsFamily._();

/// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
/// liront les familles. Libéré avec l'écran qui l'affiche.

final class StayNewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PublishedDayDto>>,
          List<PublishedDayDto>,
          FutureOr<List<PublishedDayDto>>
        >
    with
        $FutureModifier<List<PublishedDayDto>>,
        $FutureProvider<List<PublishedDayDto>> {
  /// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
  /// liront les familles. Libéré avec l'écran qui l'affiche.
  StayNewsProvider._({
    required StayNewsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'stayNewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$stayNewsHash();

  @override
  String toString() {
    return r'stayNewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PublishedDayDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PublishedDayDto>> create(Ref ref) {
    final argument = this.argument as String;
    return stayNews(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StayNewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stayNewsHash() => r'f3c2824dd2eb508c9357d8ac5068001ee26b834f';

/// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
/// liront les familles. Libéré avec l'écran qui l'affiche.

final class StayNewsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PublishedDayDto>>, String> {
  StayNewsFamily._()
    : super(
        retry: null,
        name: r'stayNewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Les jours publiés d'un séjour, du plus récent au plus ancien : ce que
  /// liront les familles. Libéré avec l'écran qui l'affiche.

  StayNewsProvider call(String stayId) =>
      StayNewsProvider._(argument: stayId, from: this);

  @override
  String toString() => r'stayNewsProvider';
}
