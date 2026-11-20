import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';

/// Message affiché pour chaque échec autour des nouvelles d'un séjour.
String newsErrorMessage(NewsErrorCode code) => switch (code) {
  NewsErrorCode.forbidden => 'Vous n\'avez pas (ou plus) accès à cette action.',
  NewsErrorCode.stayNotFound =>
    'Ce séjour n\'existe plus, ou vous n\'y avez plus accès.',
  NewsErrorCode.photoNotFound => 'Cette photo n\'existe plus.',
  NewsErrorCode.dayNotFound => 'Ce jour n\'existe plus.',
  NewsErrorCode.unsupportedPhoto =>
    'Seules les photos JPEG, PNG ou WebP sont acceptées.',
  NewsErrorCode.photoTooLarge => 'Photo trop lourde : 10 Mo au plus.',
  NewsErrorCode.invalidDayDate => 'Choisissez un jour du séjour.',
  NewsErrorCode.invalidSummary =>
    'Résumé trop long : 20 000 caractères au plus.',
  NewsErrorCode.dayAlreadyExists => 'Ce jour a déjà sa page.',
  NewsErrorCode.photoInAnotherDay =>
    'Une de ces photos illustre déjà un autre jour.',
  NewsErrorCode.emptyDay =>
    'Ajoutez un résumé ou des photos : un jour vide ne se publie pas.',
  NewsErrorCode.storageUnavailable =>
    'Le stockage des photos ne répond pas. Réessayez dans un instant.',
  NewsErrorCode.sessionExpired => 'Votre session a expiré.',
  NewsErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  NewsErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  NewsErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};
