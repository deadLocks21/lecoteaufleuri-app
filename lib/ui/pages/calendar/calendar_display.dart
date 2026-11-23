import 'package:flutter/material.dart';
import 'package:lecoteaufleuri/core/application/dtos/calendar.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/calendar.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

const _weekdayNames = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Les jours de la semaine en une lettre, pour les choisir : L M M J V S D.
const weekdayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Le nom d'un jour de la semaine (1 le lundi).
String weekdayName(int weekday) => _weekdayNames[weekday - 1];

/// Un jour en abrégé, pour le bandeau des jours : `lun.`.
String shortWeekday(DateTime day) =>
    '${_weekdayNames[day.weekday - 1].substring(0, 3)}.';

/// Le nom d'une catégorie.
String categoryLabel(CalendarCategory category) => switch (category) {
  CalendarCategory.daily => 'Vie quotidienne',
  CalendarCategory.movement => 'Arrivée ou départ',
  CalendarCategory.incident => 'Imprévu',
  CalendarCategory.activity => 'Activité',
};

IconData categoryIcon(CalendarCategory category) => switch (category) {
  CalendarCategory.daily => Icons.light_mode_outlined,
  CalendarCategory.movement => Icons.directions_bus_outlined,
  CalendarCategory.incident => Icons.warning_amber_rounded,
  CalendarCategory.activity => Icons.sports_soccer_outlined,
};

/// Le fond et le texte d'une catégorie : neutre pour le quotidien, vert pour
/// les activités, bleu pour les arrivées et départs, rouge pour l'imprévu.
({Color background, Color foreground, Color accent}) categoryColors(
  ColorScheme colors,
  CalendarCategory category,
) => switch (category) {
  CalendarCategory.daily => (
    background: colors.surfaceContainerHighest,
    foreground: colors.onSurfaceVariant,
    accent: colors.outline,
  ),
  CalendarCategory.movement => (
    background: colors.secondaryContainer,
    foreground: colors.onSecondaryContainer,
    accent: colors.secondary,
  ),
  CalendarCategory.incident => (
    background: colors.errorContainer,
    foreground: colors.onErrorContainer,
    accent: colors.error,
  ),
  CalendarCategory.activity => (
    background: colors.primaryContainer,
    foreground: colors.onPrimaryContainer,
    accent: colors.primary,
  ),
};

/// Une heure du séjour : `08:00`.
String displayClock(ClockTime time) => time.format();

/// Les heures d'une occurrence le jour [day] : `08:00 – 09:00`, `07:45`, ou
/// `Toute la journée` (aussi pour un jour au milieu d'un événement sur
/// plusieurs jours).
String displayHours(CalendarOccurrenceDto occurrence, DateTime day) {
  final start = occurrence.startTime;
  final end = occurrence.endTime;
  if (start == null) return 'Toute la journée';
  final starts = occurrence.startsOn == day;
  final ends = occurrence.endsOn == day;
  return switch ((starts, ends)) {
    (true, true) =>
      end == null
          ? displayClock(start)
          : '${displayClock(start)} – ${displayClock(end)}',
    (true, false) => 'Dès ${displayClock(start)}',
    (false, true) =>
      end == null ? 'Toute la journée' : 'Jusqu\'à ${displayClock(end)}',
    (false, false) => 'Toute la journée',
  };
}

/// Quand a lieu une occurrence, en une ligne : `Lundi 12 juillet · 08:00 –
/// 09:00`, `Du 20 au 22 juillet 2027`.
String displayWhen(CalendarOccurrenceDto occurrence) {
  if (occurrence.spansSeveralDays) {
    final dates = displayStayDates(occurrence.startsOn, occurrence.endsOn);
    return switch ((occurrence.startTime, occurrence.endTime)) {
      (final start?, final end?) =>
        '$dates · de ${displayClock(start)} à ${displayClock(end)}',
      _ => dates,
    };
  }
  return '${displayNewsDay(occurrence.startsOn)} · '
      '${displayHours(occurrence, occurrence.startsOn)}';
}

/// Les jours d'une série : `Tous les jours`, `Du lundi au vendredi`, `Le
/// mardi et le jeudi`, `Les lundi, mercredi et vendredi`.
String displayWeekdays(List<int> weekdays) {
  final days = {...weekdays}.toList()..sort();
  if (days.length == 7) return 'Tous les jours';
  if (days.isEmpty) return 'Aucun jour';
  if (days.length == 1) return 'Le ${weekdayName(days.first)}';
  final consecutive = days.last - days.first == days.length - 1;
  if (consecutive && days.length > 2) {
    return 'Du ${weekdayName(days.first)} au ${weekdayName(days.last)}';
  }
  final names = [for (final day in days) weekdayName(day)];
  final listed =
      '${names.sublist(0, names.length - 1).join(', ')} et ${names.last}';
  return days.length == 2 ? 'Le $listed' : 'Les $listed';
}

/// Une série, en une ligne : `Tous les jours, du 11 au 24 juillet 2027`.
String displaySeries(EntryDraftDto draft) {
  final dates = displayStayDates(draft.startsOn, draft.endsOn);
  return '${displayWeekdays(draft.weekdays ?? const [])}, '
      '${dates[0].toLowerCase()}${dates.substring(1)}';
}

/// Quand a lieu tout un événement, en une ligne.
String displayDraftWhen(EntryDraftDto draft) {
  final hours = switch ((draft.startTime, draft.endTime)) {
    (null, _) => 'à la journée',
    (final start?, null) => 'à ${displayClock(start)}',
    (final start?, final end?) =>
      'de ${displayClock(start)} à ${displayClock(end)}',
  };
  if (draft.isRecurring) return '${displaySeries(draft)}, $hours';
  if (draft.startsOn != draft.endsOn) {
    return '${displayStayDates(draft.startsOn, draft.endsOn)}, $hours';
  }
  return '${displayNewsDay(draft.startsOn)}, $hours';
}

/// Ce qui empêche des dates et des heures de former un événement.
String scheduleProblemMessage(ScheduleProblem problem) => switch (problem) {
  ScheduleProblem.endWithoutStart =>
    'Une heure de fin demande une heure de début.',
  ScheduleProblem.endBeforeStart => 'La fin doit suivre le début.',
  ScheduleProblem.severalDaysWithoutEnd =>
    'Sur plusieurs jours, une heure de début demande une heure de fin.',
  ScheduleProblem.noWeekday => 'Choisissez au moins un jour de la semaine.',
  ScheduleProblem.noDay =>
    'Aucun de ces jours de la semaine ne tombe entre ces dates.',
};

/// La pastille d'une catégorie.
class CategoryChip extends StatelessWidget {
  final CalendarCategory category;

  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = categoryColors(Theme.of(context).colorScheme, category);
    return Chip(
      avatar: Icon(categoryIcon(category), size: 16, color: colors.foreground),
      label: Text(categoryLabel(category)),
      labelStyle: TextStyle(color: colors.foreground),
      backgroundColor: colors.background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
