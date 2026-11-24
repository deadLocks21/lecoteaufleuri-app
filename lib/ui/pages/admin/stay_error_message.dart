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
  StayErrorCode.invalidPersonName => 'Le prénom et le nom sont obligatoires.',
  StayErrorCode.notAcm =>
    'Seul un séjour ACM a une équipe (directeurs, adjoints, animateurs).',
  StayErrorCode.hasTeam =>
    'Ce séjour a une équipe : retirez ses directeurs, adjoints et animateurs '
        'avant de le passer hors ACM.',
  StayErrorCode.entriesOutsideDates =>
    'Des jours des nouvelles ou des événements du calendrier tombent hors de '
        'ces dates : déplacez-les ou supprimez-les d\'abord.',
  StayErrorCode.alreadyDirector => 'Cette personne dirige déjà le séjour.',
  StayErrorCode.alreadyDeputy =>
    'Cette personne fait déjà partie des adjoints du séjour.',
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
