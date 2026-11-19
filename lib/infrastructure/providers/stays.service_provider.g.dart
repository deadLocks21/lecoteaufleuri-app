// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stays.service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(staysService)
final staysServiceProvider = StaysServiceProvider._();

final class StaysServiceProvider
    extends
        $FunctionalProvider<
          StaysApplicationService,
          StaysApplicationService,
          StaysApplicationService
        >
    with $Provider<StaysApplicationService> {
  StaysServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staysServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staysServiceHash();

  @$internal
  @override
  $ProviderElement<StaysApplicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StaysApplicationService create(Ref ref) {
    return staysService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaysApplicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaysApplicationService>(value),
    );
  }
}

String _$staysServiceHash() => r'98804885eb3414caf945bc533df8527276302032';
