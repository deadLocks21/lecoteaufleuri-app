import 'package:lecoteaufleuri/core/domain/model/calendar.dart';

/// Port du calendrier d'un séjour (cf. `ACCES.md` du dépôt lecoteaufleuri/dev,
/// « Calendrier du séjour »). L'API vérifie chaque droit à chaque appel ; tout
/// échec est signalé par une `CalendarException`.
abstract interface class CalendarRepository {
  /// Les événements du séjour, du premier au dernier. Toute l'équipe.
  Future<List<CalendarEntry>> entries(String stayId);

  /// La direction, pour tout ce qui suit jusqu'aux suggestions.
  Future<CalendarEntry> create(String stayId, EntryDraft draft);

  /// Tout l'événement (toute la série) : les occurrences modifiées à part le
  /// restent, tant qu'elles en font partie.
  Future<CalendarEntry> update(String stayId, String entryId, EntryDraft draft);

  /// L'événement et toute sa série.
  Future<void> delete(String stayId, String entryId);

  /// L'occurrence de [day] (minuit UTC), ce jour-là seulement.
  Future<CalendarEntry> changeOccurrence(
    String stayId,
    String entryId,
    DateTime day,
    OccurrenceDraft draft,
  );

  Future<CalendarEntry> cancelOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  );

  /// Rend l'occurrence à sa série.
  Future<CalendarEntry> restoreOccurrence(
    String stayId,
    String entryId,
    DateTime day,
  );

  /// Toutes pour la direction, les siennes pour un animateur ; celles qui
  /// attendent d'abord.
  Future<List<CalendarSuggestion>> suggestions(String stayId);

  /// Un ajout ([entryId] nul, [proposal] : tout un événement), un changement
  /// (de la série, ou de l'occurrence de [occurrenceDay]) ou une annulation
  /// ([proposal] nul). Toute l'équipe.
  Future<CalendarSuggestion> suggest(
    String stayId, {
    required SuggestionKind kind,
    String? entryId,
    DateTime? occurrenceDay,
    CalendarDraft? proposal,
    String message,
  });

  /// Son auteur, tant qu'elle attend.
  Future<void> withdraw(String stayId, String suggestionId);

  /// La direction : telle quelle, ou avec la proposition [adjusted].
  Future<CalendarSuggestion> accept(
    String stayId,
    String suggestionId, {
    CalendarDraft? adjusted,
  });

  Future<CalendarSuggestion> decline(
    String stayId,
    String suggestionId, {
    String response,
  });

  /// Le lien d'abonnement du compte, créé à la première demande.
  Future<CalendarFeed> feed(String stayId);

  /// Un nouveau lien : l'ancien ne marche plus.
  Future<CalendarFeed> renewFeed(String stayId);
}
