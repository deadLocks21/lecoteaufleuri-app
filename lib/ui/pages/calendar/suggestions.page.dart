import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar_suggestions.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_calendar.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/entry_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/occurrence_actions.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';

/// Les suggestions du calendrier (cf. `ACCES.md`, « Calendrier du
/// séjour ») :
/// - la direction les voit toutes, avec leur auteur, et les accepte (telles
///   quelles ou ajustées : le calendrier change) ou les refuse ;
/// - un animateur voit les siennes et leur suite, et retire celles qui
///   attendent.
class CalendarSuggestionsPage extends ConsumerWidget {
  final StayDto stay;
  final bool direction;

  const CalendarSuggestionsPage({
    super.key,
    required this.stay,
    required this.direction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(
      calendarSuggestionsControllerProvider(stay.id),
    );
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: switch ((suggestions.value, suggestions.error)) {
          (final List<CalendarSuggestionDto> list, _) => RefreshIndicator(
            onRefresh: () => ref.refresh(
              calendarSuggestionsControllerProvider(stay.id).future,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
              children: [
                Text(
                  direction
                      ? 'Ce que l\'équipe propose. Accepter met le calendrier '
                            'à jour ; vous pouvez ajuster la proposition avant.'
                      : 'Ce que vous avez proposé à la direction, et sa '
                            'réponse. Proposez depuis le calendrier : le bouton '
                            '« Proposer », ou un événement.',
                  style: muted,
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      direction
                          ? 'Aucune suggestion pour l\'instant.'
                          : 'Vous n\'avez encore rien proposé.',
                      key: const Key('noSuggestions'),
                      textAlign: TextAlign.center,
                      style: muted,
                    ),
                  ),
                for (final suggestion in list)
                  _SuggestionCard(
                    stay: stay,
                    suggestion: suggestion,
                    direction: direction,
                  ),
              ],
            ),
          ),
          (_, final Object error) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  calendarErrorMessage(
                    error is CalendarException
                        ? error.code
                        : CalendarErrorCode.unknown,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                    calendarSuggestionsControllerProvider(stay.id),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}

class _SuggestionCard extends ConsumerWidget {
  final StayDto stay;
  final CalendarSuggestionDto suggestion;
  final bool direction;

  const _SuggestionCard({
    required this.stay,
    required this.suggestion,
    required this.direction,
  });

  /// Ce que propose la suggestion, en une ligne de titre.
  String get _headline {
    final title = suggestion.targetTitle;
    final day = suggestion.occurrenceDay;
    final where = day == null ? '' : ' le ${displayNewsDay(day).toLowerCase()}';
    return switch (suggestion.kind) {
      SuggestionKind.add => 'Nouvel événement',
      SuggestionKind.change =>
        day == null ? 'Changer « $title »' : 'Changer « $title »$where',
      SuggestionKind.cancel =>
        day == null ? 'Annuler « $title »' : 'Annuler « $title »$where',
    };
  }

  /// Ce que deviendrait l'événement.
  String? get _proposal {
    if (suggestion.entryProposal case final draft?) {
      return displayDraftSummary(draft);
    }
    if (suggestion.occurrenceProposal case final draft?) {
      final hours = switch ((draft.startTime, draft.endTime)) {
        (null, _) => 'toute la journée',
        (final start?, null) => 'à ${start.format()}',
        (final start?, final end?) => 'de ${start.format()} à ${end.format()}',
      };
      return '${draft.title} — $hours'
          '${draft.place.isEmpty ? '' : ' · ${draft.place}'}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final proposal = _proposal;
    final icon = switch (suggestion.kind) {
      SuggestionKind.add => Icons.add_circle_outline,
      SuggestionKind.change => Icons.edit_outlined,
      SuggestionKind.cancel => Icons.event_busy_outlined,
    };

    return Card(
      key: Key('suggestion-${suggestion.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_headline, style: theme.textTheme.titleMedium),
                ),
                _StatusChip(status: suggestion.status),
              ],
            ),
            if (proposal != null) ...[
              const SizedBox(height: 8),
              Text(proposal),
            ],
            if (suggestion.entryProposal?.category case final category?) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: CategoryChip(category: category),
              ),
            ],
            if (suggestion.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '« ${suggestion.message} »',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              [
                if (direction)
                  suggestion.mine
                      ? 'Par vous'
                      : 'Par ${suggestion.authorName ?? 'un ancien membre de l\'équipe'}',
                displayInstant(suggestion.createdAt),
              ].join(' · '),
              style: muted,
            ),
            if (suggestion.response.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Réponse de la direction : ${suggestion.response}',
                key: const Key('suggestionResponse'),
              ),
            ],
            if (suggestion.isPending) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (suggestion.mine && !direction)
                    TextButton(
                      key: const Key('withdrawSuggestion'),
                      onPressed: () => _withdraw(context, ref),
                      child: const Text('Retirer'),
                    ),
                  if (direction) ...[
                    TextButton(
                      key: const Key('declineSuggestion'),
                      onPressed: () => _decline(context, ref),
                      child: const Text('Refuser'),
                    ),
                    FilledButton(
                      key: const Key('acceptSuggestion'),
                      onPressed: () => _accept(context, ref),
                      child: const Text('Accepter'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  CalendarSuggestionsController _controller(WidgetRef ref) =>
      ref.read(calendarSuggestionsControllerProvider(stay.id).notifier);

  void _tell(BuildContext context, CalendarErrorCode? error, String success) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error == null ? success : calendarErrorMessage(error)),
        ),
      );
  }

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirm(
      context,
      title: 'Retirer cette suggestion ?',
      content: 'La direction ne la verra plus.',
      action: 'Retirer',
    );
    if (!confirmed || !context.mounted) return;
    final error = await _controller(ref).withdraw(suggestion.id);
    if (context.mounted) _tell(context, error, 'Suggestion retirée.');
  }

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final response = await askMessage(
      context,
      title: 'Refuser cette suggestion ?',
      hint: 'Une réponse pour son auteur (facultatif)',
      action: 'Refuser',
    );
    if (response == null || !context.mounted) return;
    final error = await _controller(
      ref,
    ).decline(suggestion.id, response: response);
    if (context.mounted) _tell(context, error, 'Suggestion refusée.');
  }

  /// Une annulation se confirme ; un ajout ou un changement s'ouvre dans
  /// l'éditeur, pour l'ajuster avant d'accepter.
  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final controller = _controller(ref);
    if (suggestion.kind == SuggestionKind.cancel) {
      final confirmed = await confirm(
        context,
        title: 'Accepter l\'annulation ?',
        content: suggestion.occurrenceDay == null
            ? '« ${suggestion.targetTitle} » disparaît du calendrier.'
            : '« ${suggestion.targetTitle} » est annulé ce jour-là.',
        action: 'Accepter',
      );
      if (!confirmed || !context.mounted) return;
      final error = await controller.accept(suggestion.id);
      if (context.mounted) {
        _tell(
          context,
          error,
          'Suggestion acceptée : le calendrier est à jour.',
        );
      }
      return;
    }

    final day = suggestion.occurrenceDay;
    final current = suggestion.entryId == null
        ? null
        : ref
              .read(stayCalendarControllerProvider(stay.id))
              .value
              ?.entry(suggestion.entryId!);
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryEditorPage(
          stay: stay,
          title: 'Accepter la suggestion',
          submitLabel: 'Accepter',
          intro:
              'Ajustez la proposition si besoin : le calendrier sera mis à '
              'jour tel que vous l\'acceptez.',
          entry: suggestion.entryProposal ?? current?.draft,
          occurrenceDay: day,
          occurrence: suggestion.occurrenceProposal,
          onSubmit: ({entry, occurrence, required message}) => controller
              .accept(suggestion.id, entry: entry, occurrence: occurrence),
        ),
      ),
    );
    if (done == true && context.mounted) {
      _tell(context, null, 'Suggestion acceptée : le calendrier est à jour.');
    }
  }
}

class _StatusChip extends StatelessWidget {
  final SuggestionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (status) {
      SuggestionStatus.pending => (
        'En attente',
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      SuggestionStatus.accepted => (
        'Acceptée',
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      SuggestionStatus.declined => (
        'Refusée',
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return Chip(
      key: Key('status-${status.name}'),
      label: Text(label),
      labelStyle: TextStyle(color: foreground),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
