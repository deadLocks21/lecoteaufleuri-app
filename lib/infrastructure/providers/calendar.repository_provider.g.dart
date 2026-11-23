// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar.repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, calendrier de
/// démo en mémoire sinon. En mémoire, les droits suivent le compte connecté
/// et son rôle dans les séjours de démo, comme l'API les tire de l'appelant.

@ProviderFor(calendarRepository)
final calendarRepositoryProvider = CalendarRepositoryProvider._();

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, calendrier de
/// démo en mémoire sinon. En mémoire, les droits suivent le compte connecté
/// et son rôle dans les séjours de démo, comme l'API les tire de l'appelant.

final class CalendarRepositoryProvider
    extends
        $FunctionalProvider<
          CalendarRepository,
          CalendarRepository,
          CalendarRepository
        >
    with $Provider<CalendarRepository> {
  /// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, calendrier de
  /// démo en mémoire sinon. En mémoire, les droits suivent le compte connecté
  /// et son rôle dans les séjours de démo, comme l'API les tire de l'appelant.
  CalendarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalendarRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarRepository create(Ref ref) {
    return calendarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarRepository>(value),
    );
  }
}

String _$calendarRepositoryHash() =>
    r'715f713793489100ce0daf7eb6e8d49656100b7c';
