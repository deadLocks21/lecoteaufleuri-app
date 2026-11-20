import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

const _weekdays = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

const _shortMonths = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _capitalized(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// Le jour raconté, tel qu'on titre une page : `Lundi 12 juillet`.
String displayNewsDay(DateTime day) {
  final dated = displayDay(day);
  return _capitalized(
    '${_weekdays[day.weekday - 1]} ${dated.substring(0, dated.lastIndexOf(' '))}',
  );
}

/// Un jour en court, pour une pastille : `12 juil.`.
String displayShortDay(DateTime day) =>
    '${day.day} ${_shortMonths[day.month - 1]}';

/// Une heure, dans le fuseau de l'appareil : `lundi 12 juillet 2027 à 20:00`.
String displayInstant(DateTime instant) {
  final local = instant.toLocal();
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '${_weekdays[local.weekday - 1]} ${displayDay(local)} à $time';
}

/// Le titre d'une section de photos, selon leur tri.
String photoSortingTitle(PhotoSorting sorting) => switch (sorting) {
  PhotoSorting.kept => 'Retenues',
  PhotoSorting.pending => 'À trier',
  PhotoSorting.discarded => 'Écartées',
};

/// Le nom court du tri d'une photo.
String photoSortingLabel(PhotoSorting sorting) => switch (sorting) {
  PhotoSorting.kept => 'Retenue',
  PhotoSorting.pending => 'À trier',
  PhotoSorting.discarded => 'Écartée',
};

/// Où en est la publication d'un jour, en un mot.
String dayStatusLabel(DayStatus status) => switch (status) {
  DayStatus.draft => 'Brouillon',
  DayStatus.scheduled => 'Programmé',
  DayStatus.published => 'Publié',
};

/// Ce que la publication d'un jour veut dire pour les familles.
String dayStatusDescription(DayStatus status, DateTime? publishAt) =>
    switch ((status, publishAt)) {
      (DayStatus.scheduled, final DateTime at) =>
        'Paraîtra le ${displayInstant(at)}.',
      (DayStatus.published, final DateTime at) =>
        'Visible des familles depuis le ${displayInstant(at)}. '
            'Vos corrections se voient aussitôt.',
      _ => 'Invisible des familles tant qu\'il n\'est pas publié.',
    };

/// `aucune photo`, `1 photo`, `3 photos`.
String photoCount(int count) => switch (count) {
  0 => 'aucune photo',
  1 => '1 photo',
  _ => '$count photos',
};
