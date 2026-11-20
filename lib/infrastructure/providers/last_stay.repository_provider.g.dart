// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_stay.repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lastStayRepository)
final lastStayRepositoryProvider = LastStayRepositoryProvider._();

final class LastStayRepositoryProvider
    extends
        $FunctionalProvider<
          LastStayRepository,
          LastStayRepository,
          LastStayRepository
        >
    with $Provider<LastStayRepository> {
  LastStayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastStayRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastStayRepositoryHash();

  @$internal
  @override
  $ProviderElement<LastStayRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LastStayRepository create(Ref ref) {
    return lastStayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastStayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastStayRepository>(value),
    );
  }
}

String _$lastStayRepositoryHash() =>
    r'a0b85df99bca7962d0faf6624b2550c006da653a';
