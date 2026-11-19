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

  /// Administration des séjours (admins seulement).
  static const adminStays = '/api/admin/stays';

  /// Un séjour et son équipe (admin, directeurs, adjoints).
  static String stay(String id) => '/api/stays/$id';
  static String stayDirectors(String id) => '${stay(id)}/directors';
  static String stayDirector(String id, String accountId) =>
      '${stayDirectors(id)}/$accountId';
  static String stayDeputies(String id) => '${stay(id)}/deputies';
  static String stayDeputy(String id, String accountId) =>
      '${stayDeputies(id)}/$accountId';
  static String stayAnimators(String id) => '${stay(id)}/animators';
  static String stayAnimator(String id, String accountId) =>
      '${stayAnimators(id)}/$accountId';

  /// Les séjours où le compte connecté est directeur ou adjoint.
  static const myStays = '/api/me/stays';
}
