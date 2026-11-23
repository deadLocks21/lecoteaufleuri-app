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

  /// Les séjours où le compte connecté a un rôle.
  static const myStays = '/api/me/stays';

  /// Les nouvelles d'un séjour : photos de l'équipe, jours de la direction,
  /// lecture des jours publiés.
  static String stayPhotos(String id) => '${stay(id)}/photos';
  static String stayPhoto(String id, String photoId) =>
      '${stayPhotos(id)}/$photoId';
  static String stayPhotoSorting(String id, String photoId) =>
      '${stayPhoto(id, photoId)}/sorting';
  static String stayPhotoImage(String id, String photoId) =>
      '${stayPhoto(id, photoId)}/image';
  static String stayDays(String id) => '${stay(id)}/days';
  static String stayDay(String id, String dayId) => '${stayDays(id)}/$dayId';
  static String stayDayPhotos(String id, String dayId) =>
      '${stayDay(id, dayId)}/photos';
  static String stayDayPublication(String id, String dayId) =>
      '${stayDay(id, dayId)}/publication';
  static String stayNews(String id) => '${stay(id)}/news';

  /// Le calendrier d'un séjour : ses événements, leurs occurrences, les
  /// suggestions de l'équipe et le lien d'abonnement du compte.
  static String stayCalendar(String id) => '${stay(id)}/calendar';
  static String stayCalendarEntries(String id) => '${stayCalendar(id)}/entries';
  static String stayCalendarEntry(String id, String entryId) =>
      '${stayCalendarEntries(id)}/$entryId';
  static String stayCalendarOccurrence(String id, String entryId, String day) =>
      '${stayCalendarEntry(id, entryId)}/occurrences/$day';
  static String stayCalendarSuggestions(String id) =>
      '${stayCalendar(id)}/suggestions';
  static String stayCalendarSuggestion(String id, String suggestionId) =>
      '${stayCalendarSuggestions(id)}/$suggestionId';
  static String stayCalendarFeed(String id) => '${stayCalendar(id)}/feed';
}
