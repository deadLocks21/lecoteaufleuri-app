import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_base_url.provider.g.dart';

/// Valeur qui fait tourner l'app sans backend (implémentations `InMemory*`).
const inMemoryApiBaseUrl = 'memory';

bool isInMemoryMode(String apiBaseUrl) =>
    apiBaseUrl.isEmpty || apiBaseUrl == inMemoryApiBaseUrl;

/// Origine de l'API, fixée à la compilation :
///
/// ```sh
/// flutter run --dart-define=API_BASE_URL=http://localhost:7780   # simulateur iOS, desktop
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:7780    # émulateur Android
/// ```
///
/// Sans `API_BASE_URL`, l'app reste en mode mémoire : compte de démo
/// `06 12 34 56 78`, code `000000`.
@Riverpod(keepAlive: true)
String apiBaseUrl(Ref ref) => const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: inMemoryApiBaseUrl,
);
