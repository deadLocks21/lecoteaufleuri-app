// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(newsService)
final newsServiceProvider = NewsServiceProvider._();

final class NewsServiceProvider
    extends
        $FunctionalProvider<
          NewsApplicationService,
          NewsApplicationService,
          NewsApplicationService
        >
    with $Provider<NewsApplicationService> {
  NewsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsServiceHash();

  @$internal
  @override
  $ProviderElement<NewsApplicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NewsApplicationService create(Ref ref) {
    return newsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewsApplicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewsApplicationService>(value),
    );
  }
}

String _$newsServiceHash() => r'56f9cf2635e6670dad97354a9502757dbd822c6e';
