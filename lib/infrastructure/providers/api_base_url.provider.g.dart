// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_base_url.provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Origine de l'API, fixée à la compilation :
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, desktop
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
/// ```
///
/// Sans `API_BASE_URL`, l'app reste en mode mémoire : compte de démo
/// `06 12 34 56 78`, code `000000`.

@ProviderFor(apiBaseUrl)
final apiBaseUrlProvider = ApiBaseUrlProvider._();

/// Origine de l'API, fixée à la compilation :
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, desktop
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
/// ```
///
/// Sans `API_BASE_URL`, l'app reste en mode mémoire : compte de démo
/// `06 12 34 56 78`, code `000000`.

final class ApiBaseUrlProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// Origine de l'API, fixée à la compilation :
  ///
  /// ```sh
  /// flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, desktop
  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
  /// ```
  ///
  /// Sans `API_BASE_URL`, l'app reste en mode mémoire : compte de démo
  /// `06 12 34 56 78`, code `000000`.
  ApiBaseUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiBaseUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiBaseUrlHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return apiBaseUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$apiBaseUrlHash() => r'9ea2a4e91c2e9006529a7aaa65fa918c60f6a3e1';
