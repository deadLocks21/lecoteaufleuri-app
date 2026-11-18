// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stay.repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, séjours de démo en
/// mémoire sinon.

@ProviderFor(stayRepository)
final stayRepositoryProvider = StayRepositoryProvider._();

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, séjours de démo en
/// mémoire sinon.

final class StayRepositoryProvider
    extends $FunctionalProvider<StayRepository, StayRepository, StayRepository>
    with $Provider<StayRepository> {
  /// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, séjours de démo en
  /// mémoire sinon.
  StayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stayRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stayRepositoryHash();

  @$internal
  @override
  $ProviderElement<StayRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StayRepository create(Ref ref) {
    return stayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StayRepository>(value),
    );
  }
}

String _$stayRepositoryHash() => r'b088c1f3551d1833afebaf9372d20c61a839ee56';
