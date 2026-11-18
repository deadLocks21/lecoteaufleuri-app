/// Chemins de l'API, ajoutés à l'origine configurée (`apiBaseUrlProvider`).
/// Contrat : `API.md` du dépôt api.
abstract final class ApiEndpoints {
  /// Préfixe des routes publiques de connexion : jamais de Bearer dessus.
  static const authPrefix = '/api/auth/';

  static const requestOtp = '/api/auth/request-otp';
  static const verifyOtp = '/api/auth/verify-otp';

  /// Le compte de la session en cours.
  static const me = '/api/me';

  /// Administration des comptes (admins seulement).
  static const adminUsers = '/api/admin/users';
  static String adminUser(String id) => '$adminUsers/$id';
  static String adminUserAdmin(String id) => '${adminUser(id)}/admin';
  static String adminUserRevokeSessions(String id) =>
      '${adminUser(id)}/revoke-sessions';
}
