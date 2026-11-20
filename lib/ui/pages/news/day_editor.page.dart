import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news_days.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/days.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/news/photo_pool.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/news_retry.widget.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// La page d'un jour, telle que la direction la compose : son résumé, ses
/// photos (piochées, dans l'ordre voulu) et sa publication — tout de suite,
/// à une heure donnée, ou retirée. Un jour publié reste modifiable.
class DayEditorPage extends ConsumerStatefulWidget {
  final StayDto stay;
  final String dayId;

  const DayEditorPage({super.key, required this.stay, required this.dayId});

  @override
  ConsumerState<DayEditorPage> createState() => _DayEditorPageState();
}

class _DayEditorPageState extends ConsumerState<DayEditorPage> {
  final _summary = TextEditingController();

  /// Le résumé tel qu'enregistré : le champ s'en écarte tant qu'on n'a pas
  /// enregistré.
  String? _saved;
  bool _busy = false;

  /// On quitte la page en abandonnant le résumé en cours.
  bool _discarded = false;

  NewsDaysController get _days =>
      ref.read(newsDaysControllerProvider(widget.stay.id).notifier);

  bool get _dirty =>
      !_discarded && _saved != null && _summary.text.trim() != _saved;

  @override
  void dispose() {
    _summary.dispose();
    super.dispose();
  }

  void _tell(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  /// Lance [action] ; dit [success] si elle réussit, l'erreur sinon.
  Future<bool> _run(
    Future<DayResult> Function() action,
    String? success,
  ) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return false;
    setState(() {
      _busy = false;
      if (result.day case final day?) _saved = day.summary;
    });
    if (result.error case final error?) {
      _tell(newsErrorMessage(error));
      return false;
    }
    if (success != null) _tell(success);
    return true;
  }

  Future<bool> _saveSummary(NewsDayDto day) => _run(
    () => _days.edit(day.id, date: day.date, summary: _summary.text),
    'Résumé enregistré.',
  );

  /// Enregistre d'abord un résumé en cours, pour publier ce qu'on voit.
  Future<void> _publish(NewsDayDto day, {DateTime? at}) async {
    if (_dirty && !await _saveSummary(day)) return;
    await _run(
      () => _days.publish(day.id, at: at),
      at == null ? 'Jour publié.' : 'Publication programmée.',
    );
  }

  Future<void> _schedule(NewsDayDto day) async {
    final now = DateTime.now();
    final initial =
        day.publishAt?.toLocal() ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, now.month, now.day),
      initialDate: initial.isBefore(now) ? now : initial,
      helpText: 'Jour de publication',
      confirmText: 'Suivant',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: day.publishAt == null
          ? const TimeOfDay(hour: 20, minute: 0)
          : TimeOfDay.fromDateTime(initial),
      helpText: 'Heure de publication',
    );
    if (time == null || !mounted) return;
    final at = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!at.isAfter(DateTime.now())) {
      return _tell('Choisissez une heure à venir, ou publiez tout de suite.');
    }
    await _publish(day, at: at);
  }

  Future<void> _unpublish(NewsDayDto day) async {
    final confirmed = await _confirm(
      title: 'Dépublier ce jour ?',
      content:
          'Il disparaît des nouvelles des familles et redevient un brouillon.',
      action: 'Dépublier',
    );
    if (confirmed) await _run(() => _days.unpublish(day.id), 'Jour dépublié.');
  }

  Future<void> _changeDate(NewsDayDto day, List<NewsDayDto> all) async {
    final date = await pickStayDay(
      context,
      widget.stay,
      taken: {
        for (final other in all)
          if (other.id != day.id) other.date,
      },
      initial: DateTime(day.date.year, day.date.month, day.date.day),
      helpText: 'Jour raconté',
    );
    if (date == null || date == day.date || !mounted) return;
    await _run(
      () => _days.edit(day.id, date: date, summary: _summary.text),
      'Date changée.',
    );
  }

  Future<void> _delete(NewsDayDto day) async {
    final confirmed = await _confirm(
      title: 'Supprimer ce jour ?',
      content:
          'Sa page disparaît, publiée ou non. Ses photos restent dans la '
          'pioche.',
      action: 'Supprimer',
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final error = await _days.delete(day.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) return _tell(newsErrorMessage(error));
    setState(() => _discarded = true);
    Navigator.of(context).pop();
  }

  Future<void> _pickPhotos(NewsDayDto day) async {
    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => PhotoPoolPage(
          stayId: widget.stay.id,
          dayId: day.id,
          selected: day.photoIds,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _run(() => _days.setPhotos(day.id, selected), null);
  }

  Future<void> _setPhotos(NewsDayDto day, List<String> photoIds) =>
      _run(() => _days.setPhotos(day.id, photoIds), null);

  Future<bool> _confirm({
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
              key: const Key('confirmButton'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(newsDaysControllerProvider(widget.stay.id));
    final all = days.value ?? const <NewsDayDto>[];
    final day = all.where((d) => d.id == widget.dayId).firstOrNull;
    if (day != null && _saved == null) {
      _saved = day.summary;
      _summary.text = day.summary;
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirm(
          title: 'Quitter sans enregistrer ?',
          content: 'Le résumé modifié sera perdu.',
          action: 'Quitter',
        );
        if (leave && context.mounted) {
          setState(() => _discarded = true);
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(day == null ? 'Jour' : displayNewsDay(day.date)),
          actions: [
            if (day != null)
              PopupMenuButton<String>(
                key: const Key('dayMenu'),
                enabled: !_busy,
                onSelected: (choice) => switch (choice) {
                  'date' => _changeDate(day, all),
                  _ => _delete(day),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    key: Key('changeDateItem'),
                    value: 'date',
                    child: Text('Changer la date'),
                  ),
                  PopupMenuItem(
                    key: Key('deleteDayItem'),
                    value: 'delete',
                    child: Text('Supprimer ce jour'),
                  ),
                ],
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: switch ((day, days.error)) {
              (final NewsDayDto day, _) => _editor(context, day),
              (_, final Object error) => NewsRetryView.of(
                error,
                onRetry: () =>
                    ref.invalidate(newsDaysControllerProvider(widget.stay.id)),
              ),
              _ when days.hasValue => NewsRetryView(
                message: newsErrorMessage(NewsErrorCode.dayNotFound),
                onRetry: () =>
                    ref.invalidate(newsDaysControllerProvider(widget.stay.id)),
              ),
              _ => const CircularProgressIndicator(),
            },
          ),
        ),
      ),
    );
  }

  Widget _editor(BuildContext context, NewsDayDto day) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final publishable =
        _summary.text.trim().isNotEmpty || day.photoIds.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_busy)
          const LinearProgressIndicator()
        else
          const SizedBox(height: 4),
        const SizedBox(height: 8),
        _PublicationCard(
          day: day,
          busy: _busy,
          publishable: publishable,
          onPublishNow: () => _publish(day),
          onSchedule: () => _schedule(day),
          onUnpublish: () => _unpublish(day),
        ),
        const SizedBox(height: 24),
        Text('Résumé de la journée', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextField(
          key: const Key('summaryField'),
          controller: _summary,
          minLines: 5,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Ce qu\'ont vécu les enfants aujourd\'hui…',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonal(
            key: const Key('saveSummaryButton'),
            onPressed: _dirty && !_busy ? () => _saveSummary(day) : null,
            child: const Text('Enregistrer le résumé'),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Photos · ${day.photoIds.length}',
                style: theme.textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              key: const Key('pickDayPhotosButton'),
              onPressed: _busy ? null : () => _pickPhotos(day),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choisir des photos'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (day.photoIds.isEmpty)
          Text(
            'Aucune photo : piochez parmi celles de l\'équipe.',
            key: const Key('noDayPhotos'),
            style: muted,
          )
        else ...[
          SizedBox(
            height: 120,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: day.photoIds.length,
              onReorder: (from, to) {
                final ids = [...day.photoIds];
                final moved = ids.removeAt(from);
                ids.insert(to > from ? to - 1 : to, moved);
                _setPhotos(day, ids);
              },
              itemBuilder: (context, index) {
                final id = day.photoIds[index];
                return Padding(
                  key: Key('dayPhoto-$id'),
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox.square(
                    dimension: 112,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        PhotoTile(stayId: widget.stay.id, photoId: id),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: IconButton.filledTonal(
                            key: Key('removeDayPhoto-$id'),
                            tooltip: 'Retirer du jour',
                            visualDensity: VisualDensity.compact,
                            iconSize: 16,
                            onPressed: _busy
                                ? null
                                : () => _setPhotos(day, [
                                    for (final other in day.photoIds)
                                      if (other != id) other,
                                  ]),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text('Faites glisser une photo pour changer l\'ordre.', style: muted),
        ],
      ],
    );
  }
}

class _PublicationCard extends StatelessWidget {
  final NewsDayDto day;
  final bool busy;
  final bool publishable;
  final VoidCallback onPublishNow;
  final VoidCallback onSchedule;
  final VoidCallback onUnpublish;

  const _PublicationCard({
    required this.day,
    required this.busy,
    required this.publishable,
    required this.onPublishNow,
    required this.onSchedule,
    required this.onUnpublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPublish = !busy && publishable;

    return Card(
      key: const Key('publicationCard'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DayStatusChip(status: day.status),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dayStatusDescription(day.status, day.publishAt),
                    key: const Key('publicationStatus'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (!publishable && day.status == DayStatus.draft) ...[
              const SizedBox(height: 8),
              Text(
                'Ajoutez un résumé ou des photos pour publier.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (day.status != DayStatus.published)
                  FilledButton.icon(
                    key: const Key('publishNowButton'),
                    onPressed: canPublish ? onPublishNow : null,
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Publier maintenant'),
                  ),
                if (day.status != DayStatus.published)
                  OutlinedButton.icon(
                    key: const Key('scheduleButton'),
                    onPressed: canPublish ? onSchedule : null,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      day.status == DayStatus.scheduled
                          ? 'Changer l\'heure'
                          : 'Programmer…',
                    ),
                  ),
                if (day.status != DayStatus.draft)
                  TextButton.icon(
                    key: const Key('unpublishButton'),
                    onPressed: busy ? null : onUnpublish,
                    icon: const Icon(Icons.unpublished_outlined),
                    label: Text(
                      day.status == DayStatus.scheduled
                          ? 'Annuler la programmation'
                          : 'Dépublier',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
