/// Chemins de l'API, ajoutés à l'origine configurée (`apiBaseUrlProvider`).
/// Contrat : `API.md` du dépôt api.
abstract final class ApiEndpoints {
  /// Préfixe des routes publiques de connexion : jamais de Bearer dessus.
  static const authPrefix = '/api/auth/';

  static const requestOtp = '/api/auth/request-otp';
  static const verifyOtp = '/api/auth/verify-otp';
}
