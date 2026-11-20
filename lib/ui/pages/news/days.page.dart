import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lecoteaufleuri/core/application/dtos/news.dto.dart';
import 'package:lecoteaufleuri/core/application/dtos/stay.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/infrastructure/providers/news_days.controller_provider.dart';
import 'package:lecoteaufleuri/ui/pages/news/day_editor.page.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_error_message.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/news_retry.widget.dart';
import 'package:lecoteaufleuri/ui/pages/news/widgets/photo_image.widget.dart';

/// Les jours d'un séjour, tels que la direction les compose : un par date,
/// créé à l'avance ou au fil du séjour, chacun brouillon, programmé ou publié.
class NewsDaysPage extends ConsumerWidget {
  final StayDto stay;

  /// Affichée dans un onglet du module Nouvelles, sous sa barre : sans barre
  /// de titre à elle.
  final bool embedded;

  const NewsDaysPage({super.key, required this.stay, this.embedded = false});

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    List<NewsDayDto> days,
  ) async {
    final taken = {for (final day in days) day.date};
    final date = await pickStayDay(
      context,
      stay,
      taken: taken,
      helpText: 'Jour à raconter',
    );
    if (date == null || !context.mounted) return;

    final result = await ref
        .read(newsDaysControllerProvider(stay.id).notifier)
        .create(date);
    if (!context.mounted) return;
    switch (result) {
      case (day: final NewsDayDto day, error: _):
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DayEditorPage(stay: stay, dayId: day.id),
          ),
        );
      case (day: _, :final error?):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(newsErrorMessage(error))));
      default:
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(newsDaysControllerProvider(stay.id));
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final list = days.value;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: const Text('Journées')),
      floatingActionButton: list == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('newDayButton'),
              onPressed: () => _create(context, ref, list),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Nouveau jour'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: switch ((list, days.error)) {
            (final List<NewsDayDto> list, _) => RefreshIndicator(
              onRefresh: () =>
                  ref.refresh(newsDaysControllerProvider(stay.id).future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    'Une page par jour du séjour : un résumé et des photos. '
                    'Rien n\'est visible des familles avant publication.',
                    style: muted,
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Aucun jour pour l\'instant : racontez celui '
                        'd\'aujourd\'hui, ou préparez les suivants.',
                        key: const Key('noDays'),
                        textAlign: TextAlign.center,
                        style: muted,
                      ),
                    ),
                  for (final day in list)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('day-${day.id}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DayEditorPage(stay: stay, dayId: day.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox.square(
                                dimension: 56,
                                child: day.photoIds.isEmpty
                                    ? const Icon(Icons.today_outlined)
                                    : PhotoTile(
                                        stayId: stay.id,
                                        photoId: day.photoIds.first,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayNewsDay(day.date),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      day.summary.isEmpty
                                          ? 'Pas encore de résumé'
                                          : day.summary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: muted,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        DayStatusChip(status: day.status),
                                        Text(
                                          photoCount(day.photoIds.length),
                                          style: muted,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            (_, final Object error) => NewsRetryView.of(
              error,
              onRetry: () =>
                  ref.invalidate(newsDaysControllerProvider(stay.id)),
            ),
            _ => const CircularProgressIndicator(),
          },
        ),
      ),
    );
  }
}

/// Où en est un jour, en pastille.
class DayStatusChip extends StatelessWidget {
  final DayStatus status;

  const DayStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (status) {
      DayStatus.draft => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        Icons.edit_note,
      ),
      DayStatus.scheduled => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        Icons.schedule,
      ),
      DayStatus.published => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.public,
      ),
    };
    return Chip(
      key: Key('status-${status.name}'),
      avatar: Icon(icon, size: 16, color: foreground),
      label: Text(dayStatusLabel(status)),
      labelStyle: TextStyle(color: foreground),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Choisit un jour du séjour qu'aucun autre ne porte ([taken], à minuit
/// UTC) ; null si l'on renonce, ou s'il n'en reste aucun.
Future<DateTime?> pickStayDay(
  BuildContext context,
  StayDto stay, {
  required Set<DateTime> taken,
  DateTime? initial,
  required String helpText,
}) async {
  bool free(DateTime day) => !taken.contains(calendarDay(day));
  final first = DateTime(
    stay.startsOn.year,
    stay.startsOn.month,
    stay.startsOn.day,
  );
  final last = DateTime(stay.endsOn.year, stay.endsOn.month, stay.endsOn.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  var start =
      initial ??
      (today.isBefore(first)
          ? first
          : today.isAfter(last)
          ? last
          : today);
  // Le plus proche jour libre, en avançant puis en reculant.
  final candidates = [
    for (
      var d = start;
      !d.isAfter(last);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      d,
    for (
      var d = start;
      !d.isBefore(first);
      d = DateTime(d.year, d.month, d.day - 1)
    )
      d,
  ];
  final initialDate = initial ?? candidates.where(free).firstOrNull;
  if (initialDate == null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Chaque jour du séjour a déjà sa page.')),
      );
    return null;
  }
  start = initialDate;
  final picked = await showDatePicker(
    context: context,
    firstDate: first,
    lastDate: last,
    initialDate: start,
    selectableDayPredicate: (day) =>
        free(day) || (initial != null && DateUtils.isSameDay(day, initial)),
    helpText: helpText,
    confirmText: 'Valider',
  );
  return picked == null ? null : calendarDay(picked);
}
