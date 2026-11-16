/// Raisons d'échec de l'authentification, indépendantes du transport.
///
/// Les implémentations de `AuthRepository` y traduisent les `code` d'erreur de
/// l'API (cf. `API.md` du dépôt api) ; l'UI en déduit le message affiché.
enum AuthErrorCode {
  /// Le numéro saisi n'est pas un mobile français.
  invalidPhone,

  /// Aucun compte pour ce numéro : les comptes sont créés par un administrateur.
  accountNotFound,

  /// Le code saisi ne correspond pas (ou n'a pas 6 chiffres).
  invalidOtp,

  /// Plus de code utilisable : expiré, déjà utilisé ou essais épuisés.
  otpExpired,

  /// Trop de demandes ou de vérifications : il faut patienter.
  rateLimited,

  /// Le fournisseur SMS n'a pas pris le message.
  smsFailed,

  /// Rien n'a répondu (réseau, DNS, délai dépassé).
  network,

  /// Quelqu'un a répondu, mais pas l'API (page HTML, proxy…) : l'URL du
  /// serveur vise sans doute le mauvais hôte ou chemin.
  badServerUrl,

  unknown,
}

/// Échec métier d'une étape de connexion.
class AuthException implements Exception {
  final AuthErrorCode code;

  const AuthException(this.code);

  @override
  String toString() => 'AuthException(${code.name})';
}
