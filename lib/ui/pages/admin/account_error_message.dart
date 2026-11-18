import 'package:lecoteaufleuri/core/domain/exceptions/account.exception.dart';

/// Message affiché pour chaque échec de l'administration des comptes.
String accountErrorMessage(AccountErrorCode code) => switch (code) {
  AccountErrorCode.forbidden =>
    'Vous n\'avez pas (ou plus) accès à la gestion des comptes.',
  AccountErrorCode.notFound => 'Ce compte n\'existe plus.',
  AccountErrorCode.phoneTaken => 'Ce numéro est déjà celui d\'un autre compte.',
  AccountErrorCode.invalidPhone =>
    'Numéro de mobile invalide (ex. 06 12 34 56 78).',
  AccountErrorCode.invalidName => 'Le prénom et le nom sont obligatoires.',
  AccountErrorCode.lastAdmin =>
    'C\'est le dernier admin : nommez-en un autre d\'abord.',
  AccountErrorCode.sessionExpired => 'Votre session a expiré.',
  AccountErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  AccountErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  AccountErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};
