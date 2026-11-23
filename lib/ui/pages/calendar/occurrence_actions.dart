import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/application/usecases/calendar.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/calendar.exception.dart';
import 'package:lecoteaufleuri/infrastructure/providers/calendar_suggestions.controller_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_calendar.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_display.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/calendar_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/calendar/entry_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';

/// Ce qu'on peut faire d'une occurrence, selon qu'on compose le calendrier
/// (la direction) ou qu'on y propose des changements (un animateur).
enum _Action {
  editDay,
  editSeries,
  edit,
  cancelDay,
  restoreDay,
  deleteSeries,
  delete,
  suggestDay,
  suggestSeries,
  suggestChange,
  suggestCancelDay,
  suggestCancelSeries,
  suggestCancel,
}

/// La fiche d'une occurrence, et ce qu'on peut en faire.
Future<void> showOccurrenceSheet(
  BuildContext context,
  WidgetRef ref, {
  required StayDto stay,
  required CalendarOccurrenceDto occurrence,
  required bool direction,
}) async {
  final calendar = ref.read(stayCalendarControllerProvider(stay.id)).value;
  final entry = calendar?.entry(occurrence.entryId);
  if (entry == null) return;

  final action = await showModalBottomSheet<_Action>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _OccurrenceSheet(
      occurrence: occurrence,
      entry: entry,
      direction: direction,
    ),
  );
  if (action == null || !context.mounted) return;
  await _run(context, ref, stay, occurrence, entry, action);
}

class _OccurrenceSheet extends StatelessWidget {
  final CalendarOccurrenceDto occurrence;
  final CalendarEntryDto entry;
  final bool direction;

  const _OccurrenceSheet({
    required this.occurrence,
    required this.entry,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final series = entry.isRecurring;
    Widget action(_Action value, IconData icon, String label) => ListTile(
      key: Key('action-${value.name}'),
      leading: Icon(icon),
      title: Text(label),
      onTap: () => Navigator.of(context).pop(value),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occurrence.title,
                    key: const Key('occurrenceTitle'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      decoration: occurrence.cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      CategoryChip(category: occurrence.category),
                      if (occurrence.cancelled)
                        const Chip(
                          label: Text('Annulé ce jour'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (occurrence.changed)
                        const Chip(
                          label: Text('Modifié ce jour'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Line(icon: Icons.schedule, text: displayWhen(occurrence)),
                  if (series)
                    _Line(icon: Icons.repeat, text: displaySeries(entry.draft)),
                  if (occurrence.place.isNotEmpty)
                    _Line(icon: Icons.place_outlined, text: occurrence.place),
                  if (occurrence.notes.isNotEmpty)
                    _Line(icon: Icons.notes, text: occurrence.notes),
                  if (!direction) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Seule la direction modifie le calendrier : proposez-lui '
                      'un changement.',
                      style: muted,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            if (direction) ...[
              if (series) ...[
                if (!occurrence.cancelled)
                  action(
                    _Action.editDay,
                    Icons.edit_calendar_outlined,
                    'Modifier ce jour seulement',
                  ),
                action(
                  _Action.editSeries,
                  Icons.edit_outlined,
                  'Modifier toute la série',
                ),
                if (occurrence.cancelled || occurrence.changed)
                  action(
                    _Action.restoreDay,
                    Icons.restore,
                    'Rétablir comme le reste de la série',
                  )
                else
                  action(
                    _Action.cancelDay,
                    Icons.event_busy_outlined,
                    'Annuler ce jour seulement',
                  ),
                action(
                  _Action.deleteSeries,
                  Icons.delete_outline,
                  'Supprimer toute la série',
                ),
              ] else ...[
                action(_Action.edit, Icons.edit_outlined, 'Modifier'),
                action(_Action.delete, Icons.delete_outline, 'Supprimer'),
              ],
            ] else if (series) ...[
              action(
                _Action.suggestDay,
                Icons.edit_calendar_outlined,
                'Proposer un changement ce jour',
              ),
              action(
                _Action.suggestSeries,
                Icons.edit_outlined,
                'Proposer un changement de la série',
              ),
              action(
                _Action.suggestCancelDay,
                Icons.event_busy_outlined,
                'Proposer d\'annuler ce jour',
              ),
              action(
                _Action.suggestCancelSeries,
                Icons.delete_outline,
                'Proposer d\'annuler la série',
              ),
            ] else ...[
              action(
                _Action.suggestChange,
                Icons.edit_outlined,
                'Proposer un changement',
              ),
              action(
                _Action.suggestCancel,
                Icons.event_busy_outlined,
                'Proposer l\'annulation',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

Future<void> _run(
  BuildContext context,
  WidgetRef ref,
  StayDto stay,
  CalendarOccurrenceDto occurrence,
  CalendarEntryDto target,
  _Action action,
) async {
  final calendar = ref.read(stayCalendarControllerProvider(stay.id).notifier);
  final suggestions = ref.read(
    calendarSuggestionsControllerProvider(stay.id).notifier,
  );
  final day = occurrence.startsOn;
  final dayLabel = displayNewsDay(day).toLowerCase();

  void tell(CalendarErrorCode? error, String success) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error == null ? success : calendarErrorMessage(error)),
        ),
      );
  }

  Future<void> editor({
    required String title,
    required String submitLabel,
    String? intro,
    bool oneDay = false,
    bool asksMessage = false,
    required EditorSubmit onSubmit,
    required String success,
  }) async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryEditorPage(
          stay: stay,
          title: title,
          submitLabel: submitLabel,
          intro: intro,
          entry: target.draft,
          occurrenceDay: oneDay ? day : null,
          occurrence: oneDay ? occurrence.asOccurrenceDraft : null,
          asksMessage: asksMessage,
          onSubmit: onSubmit,
        ),
      ),
    );
    if (done == true) tell(null, success);
  }

  switch (action) {
    case _Action.editDay:
      await editor(
        title: 'Ce jour seulement',
        submitLabel: 'Enregistrer',
        oneDay: true,
        onSubmit: ({entry, occurrence, required message}) =>
            calendar.changeOccurrence(target.id, day, occurrence!),
        success: 'Le $dayLabel est modifié.',
      );
    case _Action.editSeries || _Action.edit:
      await editor(
        title: action == _Action.edit ? 'Modifier' : 'Toute la série',
        submitLabel: 'Enregistrer',
        intro: action == _Action.editSeries
            ? 'Les jours modifiés ou annulés à part le restent.'
            : null,
        onSubmit: ({entry, occurrence, required message}) =>
            calendar.edit(target.id, entry!),
        success: 'Événement enregistré.',
      );
    case _Action.cancelDay:
      tell(
        await calendar.setOccurrence(target.id, day, OccurrenceAction.cancel),
        'Annulé le $dayLabel.',
      );
    case _Action.restoreDay:
      tell(
        await calendar.setOccurrence(target.id, day, OccurrenceAction.restore),
        'Le $dayLabel suit de nouveau la série.',
      );
    case _Action.deleteSeries || _Action.delete:
      final series = action == _Action.deleteSeries;
      final confirmed = await confirm(
        context,
        title: series
            ? 'Supprimer toute la série ?'
            : 'Supprimer cet événement ?',
        content: series
            ? '« ${target.draft.title} » disparaît de tous les jours du séjour.'
            : '« ${target.draft.title} » disparaît du calendrier.',
        action: 'Supprimer',
      );
      if (confirmed) tell(await calendar.delete(target.id), 'Supprimé.');
    case _Action.suggestDay:
      await editor(
        title: 'Proposer un changement',
        submitLabel: 'Envoyer',
        intro: 'La direction verra votre proposition et pourra l\'accepter.',
        oneDay: true,
        asksMessage: true,
        onSubmit: ({entry, occurrence, required message}) => suggestions.change(
          target.id,
          occurrenceDay: day,
          occurrence: occurrence,
          message: message,
        ),
        success: 'Proposition envoyée à la direction.',
      );
    case _Action.suggestSeries || _Action.suggestChange:
      await editor(
        title: 'Proposer un changement',
        submitLabel: 'Envoyer',
        intro: 'La direction verra votre proposition et pourra l\'accepter.',
        asksMessage: true,
        onSubmit: ({entry, occurrence, required message}) =>
            suggestions.change(target.id, entry: entry, message: message),
        success: 'Proposition envoyée à la direction.',
      );
    case _Action.suggestCancelDay ||
        _Action.suggestCancelSeries ||
        _Action.suggestCancel:
      final oneDay = action == _Action.suggestCancelDay;
      final message = await askMessage(
        context,
        title: oneDay
            ? 'Proposer d\'annuler le $dayLabel ?'
            : action == _Action.suggestCancelSeries
            ? 'Proposer d\'annuler toute la série ?'
            : 'Proposer l\'annulation ?',
        hint: 'Pourquoi ? (facultatif)',
        action: 'Envoyer',
      );
      if (message == null) return;
      tell(
        await suggestions.cancel(
          target.id,
          occurrenceDay: oneDay ? day : null,
          message: message,
        ),
        'Proposition envoyée à la direction.',
      );
  }
}

/// Une confirmation : vrai si l'on choisit [action].
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String content,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            key: const Key('confirmAction'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

/// Un mot facultatif (pour la direction, ou en réponse) ; null si l'on
/// renonce.
Future<String?> askMessage(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _MessageDialog(title: title, hint: hint, action: action),
);

class _MessageDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String action;

  const _MessageDialog({
    required this.title,
    required this.hint,
    required this.action,
  });

  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      key: const Key('dialogMessage'),
      controller: _text,
      autofocus: true,
      maxLength: 2000,
      minLines: 2,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: widget.hint,
        border: const OutlineInputBorder(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Annuler'),
      ),
      FilledButton(
        key: const Key('sendMessage'),
        onPressed: () => Navigator.of(context).pop(_text.text),
        child: Text(widget.action),
      ),
    ],
  );
}
