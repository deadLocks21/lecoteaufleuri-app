// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar.service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calendarService)
final calendarServiceProvider = CalendarServiceProvider._();

final class CalendarServiceProvider
    extends
        $FunctionalProvider<
          CalendarApplicationService,
          CalendarApplicationService,
          CalendarApplicationService
        >
    with $Provider<CalendarApplicationService> {
  CalendarServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarServiceHash();

  @$internal
  @override
  $ProviderElement<CalendarApplicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarApplicationService create(Ref ref) {
    return calendarService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarApplicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarApplicationService>(value),
    );
  }
}

String _$calendarServiceHash() => r'6ab5bc2a081ed60e1917561b2021b79d99e9473f';
