import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';

/// Message affiché pour chaque échec de l'administration des séjours.
String stayErrorMessage(StayErrorCode code) => switch (code) {
  StayErrorCode.forbidden =>
    'Vous n\'avez pas (ou plus) accès à la gestion des séjours.',
  StayErrorCode.notFound =>
    'Ce séjour n\'existe plus, ou vous n\'y avez plus accès.',
  StayErrorCode.invalidPhone =>
    'Numéro de mobile invalide (ex. 06 12 34 56 78).',
  StayErrorCode.unknownPhone => 'Aucun compte pour ce numéro.',
  StayErrorCode.notAcm => 'Seul un séjour ACM a un directeur et des adjoints.',
  StayErrorCode.alreadyDirector => 'Cette personne dirige déjà le séjour.',
  StayErrorCode.invalidName =>
    'Le nom du séjour est obligatoire '
        '(${StayDraft.nameMaxLength} caractères au plus).',
  StayErrorCode.invalidKind => 'Choisissez la nature du séjour.',
  StayErrorCode.invalidDates =>
    'Choisissez le premier et le dernier jour du séjour.',
  StayErrorCode.sessionExpired => 'Votre session a expiré.',
  StayErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  StayErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  StayErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};
