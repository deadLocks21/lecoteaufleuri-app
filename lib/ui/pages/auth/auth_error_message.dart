import 'package:lecoteaufleuri/core/domain/exceptions/auth.exception.dart';

/// Message affiché pour chaque échec de connexion.
String authErrorMessage(AuthErrorCode code) => switch (code) {
  AuthErrorCode.invalidPhone =>
    'Numéro de mobile invalide (ex. 06 12 34 56 78).',
  AuthErrorCode.accountNotFound =>
    'Aucun compte pour ce numéro. Contactez l\'administrateur.',
  AuthErrorCode.invalidOtp => 'Code incorrect.',
  AuthErrorCode.otpExpired => 'Code expiré. Demandez un nouveau code.',
  AuthErrorCode.rateLimited =>
    'Trop de tentatives. Réessayez dans quelques minutes.',
  AuthErrorCode.smsFailed => 'Envoi du SMS impossible. Réessayez plus tard.',
  AuthErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  AuthErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  AuthErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};
