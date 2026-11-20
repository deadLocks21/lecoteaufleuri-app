// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news.repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, nouvelles de démo
/// en mémoire sinon. En mémoire, les droits suivent le compte connecté et son
/// rôle dans les séjours de démo, comme l'API les tire de l'appelant.

@ProviderFor(newsRepository)
final newsRepositoryProvider = NewsRepositoryProvider._();

/// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, nouvelles de démo
/// en mémoire sinon. En mémoire, les droits suivent le compte connecté et son
/// rôle dans les séjours de démo, comme l'API les tire de l'appelant.

final class NewsRepositoryProvider
    extends $FunctionalProvider<NewsRepository, NewsRepository, NewsRepository>
    with $Provider<NewsRepository> {
  /// Vrais appels HTTP dès qu'une `API_BASE_URL` est fournie, nouvelles de démo
  /// en mémoire sinon. En mémoire, les droits suivent le compte connecté et son
  /// rôle dans les séjours de démo, comme l'API les tire de l'appelant.
  NewsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsRepositoryHash();

  @$internal
  @override
  $ProviderElement<NewsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NewsRepository create(Ref ref) {
    return newsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NewsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NewsRepository>(value),
    );
  }
}

String _$newsRepositoryHash() => r'd8bc2d92266558ec804bb1eb208621319ea90b4e';
