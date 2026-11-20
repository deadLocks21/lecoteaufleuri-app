import 'dart:typed_data';

/// Le tri d'une photo (cf. `ACCES.md` du dépôt lecoteaufleuri/dev,
/// « Nouvelles du séjour ») : à trier en arrivant, puis retenue ou écartée
/// par son auteur ou par la direction.
enum PhotoSorting {
  pending,
  kept,
  discarded;

  /// Rang dans la pioche de la direction : les retenues d'abord, puis les
  /// photos à trier, les écartées en dernier recours.
  int get priority => switch (this) {
    PhotoSorting.kept => 0,
    PhotoSorting.pending => 1,
    PhotoSorting.discarded => 2,
  };
}

/// L'ordre de la pioche, celui de l'API : par tri, puis de la plus récente à
/// la plus ancienne.
int comparePhotosForPick(StayPhoto a, StayPhoto b) {
  final byPriority = a.sorting.priority.compareTo(b.sorting.priority);
  if (byPriority != 0) return byPriority;
  final byDate = b.uploadedAt.compareTo(a.uploadedAt);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

/// Qui a déposé une photo, tel que la direction le voit.
class PhotoAuthor {
  final String id;
  final String firstName;
  final String lastName;

  const PhotoAuthor({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
}

/// Une photo du séjour telle que l'équipe la voit pour la trier ou la
/// piocher : son tri, son auteur, et le jour qu'elle illustre ([dayId] et
/// [dayDate], à minuit UTC), s'il y en a un.
class StayPhoto {
  final String id;
  final PhotoSorting sorting;
  final DateTime uploadedAt;
  final PhotoAuthor? author;
  final bool mine;
  final String? dayId;
  final DateTime? dayDate;

  StayPhoto({
    required this.id,
    required this.sorting,
    required this.uploadedAt,
    this.author,
    required this.mine,
    this.dayId,
    this.dayDate,
  }) : assert(id.isNotEmpty, 'id cannot be empty');

  StayPhoto copyWith({
    PhotoSorting? sorting,
    String? Function()? dayId,
    DateTime? Function()? dayDate,
  }) => StayPhoto(
    id: id,
    sorting: sorting ?? this.sorting,
    uploadedAt: uploadedAt,
    author: author,
    mine: mine,
    dayId: dayId != null ? dayId() : this.dayId,
    dayDate: dayDate != null ? dayDate() : this.dayDate,
  );
}

/// Où en est un jour, à l'heure où l'API l'a rendu.
enum DayStatus {
  /// Jamais publié, ou dépublié : invisible des familles.
  draft,

  /// Publié à une heure à venir.
  scheduled,

  /// Visible des familles.
  published,
}

/// Un jour du séjour, tel que la direction le compose : sa date (minuit UTC),
/// son résumé, ses photos dans l'ordre et sa publication.
class NewsDay {
  final String id;
  final DateTime date;
  final String summary;
  final DayStatus status;
  final DateTime? publishAt;
  final List<String> photoIds;
  final DateTime updatedAt;

  NewsDay({
    required this.id,
    required this.date,
    required this.summary,
    required this.status,
    this.publishAt,
    required List<String> photoIds,
    required this.updatedAt,
  }) : photoIds = List.unmodifiable(photoIds),
       assert(id.isNotEmpty, 'id cannot be empty');

  bool get isEmpty => summary.trim().isEmpty && photoIds.isEmpty;
}

/// Un jour publié, tel que le lisent l'équipe et les familles : ni l'auteur ni
/// le tri des photos.
class PublishedDay {
  final String id;
  final DateTime date;
  final String summary;
  final DateTime publishedAt;
  final List<String> photoIds;

  PublishedDay({
    required this.id,
    required this.date,
    required this.summary,
    required this.publishedAt,
    required List<String> photoIds,
  }) : photoIds = List.unmodifiable(photoIds);
}

/// La taille d'une image demandée à l'API : une vignette pour les grilles, la
/// photo entière pour l'afficher en grand.
enum PhotoSize { thumbnail, large }

/// Une photo choisie sur l'appareil, prête à être déposée.
class PickedPhoto {
  final String name;
  final Uint8List bytes;

  const PickedPhoto({required this.name, required this.bytes});
}
