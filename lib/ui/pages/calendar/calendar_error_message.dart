import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';

/// Message affiché pour chaque échec autour du calendrier d'un séjour.
String calendarErrorMessage(CalendarErrorCode code) => switch (code) {
  CalendarErrorCode.forbidden =>
    'Vous n\'avez pas (ou plus) accès à cette action.',
  CalendarErrorCode.stayNotFound =>
    'Ce séjour n\'existe plus, ou vous n\'y avez plus accès.',
  CalendarErrorCode.entryNotFound => 'Cet événement n\'existe plus.',
  CalendarErrorCode.suggestionNotFound => 'Cette suggestion n\'existe plus.',
  CalendarErrorCode.invalidCategory => 'Choisissez une catégorie.',
  CalendarErrorCode.invalidDetails =>
    'Donnez un titre (120 caractères au plus) ; le lieu en compte 120 au '
        'plus, les notes 4 000.',
  CalendarErrorCode.invalidSchedule =>
    'Choisissez des jours du séjour, et une fin après le début.',
  CalendarErrorCode.invalidOccurrenceDay =>
    'Ce jour ne fait plus partie de la série.',
  CalendarErrorCode.invalidSuggestion =>
    'Cette suggestion ne tient pas (message de 2 000 caractères au plus).',
  CalendarErrorCode.suggestionAlreadyDecided =>
    'Cette suggestion a déjà été acceptée ou refusée.',
  CalendarErrorCode.sessionExpired => 'Votre session a expiré.',
  CalendarErrorCode.network =>
    'Connexion au serveur impossible. Vérifiez votre réseau.',
  CalendarErrorCode.badServerUrl =>
    'Le serveur ne répond pas comme l\'API Le Coteau Fleuri.',
  CalendarErrorCode.unknown => 'Une erreur est survenue. Réessayez.',
};
