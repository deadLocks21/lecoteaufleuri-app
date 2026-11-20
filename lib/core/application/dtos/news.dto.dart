import 'package:lecoteaufleuri/core/domain/model/news.dart';

/// Une photo du séjour, telle que l'UI l'affiche pour la trier ou la piocher.
class StayPhotoDto {
  final String id;
  final PhotoSorting sorting;
  final DateTime uploadedAt;

  /// `Prénom Nom` de qui l'a déposée ; null si le compte a disparu.
  final String? authorName;
  final bool mine;

  /// Le jour qu'elle illustre (minuit UTC), s'il y en a un.
  final String? dayId;
  final DateTime? dayDate;

  const StayPhotoDto({
    required this.id,
    required this.sorting,
    required this.uploadedAt,
    this.authorName,
    required this.mine,
    this.dayId,
    this.dayDate,
  });

  factory StayPhotoDto.fromDomain(StayPhoto photo) => StayPhotoDto(
    id: photo.id,
    sorting: photo.sorting,
    uploadedAt: photo.uploadedAt,
    authorName: switch (photo.author) {
      final PhotoAuthor author =>
        '${author.firstName} ${author.lastName}'.trim(),
      null => null,
    },
    mine: photo.mine,
    dayId: photo.dayId,
    dayDate: photo.dayDate,
  );
}

/// Un jour du séjour, tel que la direction le compose.
class NewsDayDto {
  final String id;
  final DateTime date;
  final String summary;
  final DayStatus status;
  final DateTime? publishAt;
  final List<String> photoIds;

  const NewsDayDto({
    required this.id,
    required this.date,
    required this.summary,
    required this.status,
    this.publishAt,
    required this.photoIds,
  });

  factory NewsDayDto.fromDomain(NewsDay day) => NewsDayDto(
    id: day.id,
    date: day.date,
    summary: day.summary,
    status: day.status,
    publishAt: day.publishAt,
    photoIds: day.photoIds,
  );

  /// Ni résumé ni photo : il ne se publie pas.
  bool get isEmpty => summary.trim().isEmpty && photoIds.isEmpty;
}

/// Un jour publié, tel que le lisent l'équipe et les familles.
class PublishedDayDto {
  final String id;
  final DateTime date;
  final String summary;
  final DateTime publishedAt;
  final List<String> photoIds;

  const PublishedDayDto({
    required this.id,
    required this.date,
    required this.summary,
    required this.publishedAt,
    required this.photoIds,
  });

  factory PublishedDayDto.fromDomain(PublishedDay day) => PublishedDayDto(
    id: day.id,
    date: day.date,
    summary: day.summary,
    publishedAt: day.publishedAt,
    photoIds: day.photoIds,
  );
}
