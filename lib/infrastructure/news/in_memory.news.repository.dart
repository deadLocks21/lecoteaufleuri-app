import 'dart:typed_data';

import 'package:lecoteaufleuri/core/domain/exceptions/news.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/core/domain/services/news.repository.dart';
import 'package:lecoteaufleuri/infrastructure/news/demo_photos.dart';

/// Le compte connecté, vu des nouvelles : de quoi décider de ses droits.
typedef NewsViewer = ({String id, bool isAdmin});

/// Une photo rangée en mémoire, avec son contenu.
class _Photo {
  final String id;
  final String stayId;
  final String authorId;
  final DateTime uploadedAt;
  final Uint8List bytes;
  PhotoSorting sorting;

  _Photo({
    required this.id,
    required this.stayId,
    required this.authorId,
    required this.uploadedAt,
    required this.bytes,
    this.sorting = PhotoSorting.pending,
  });
}

class _Day {
  final String id;
  final String stayId;
  DateTime date;
  String summary;
  List<String> photoIds;
  DateTime? publishAt;
  DateTime updatedAt;

  _Day({
    required this.id,
    required this.stayId,
    required this.date,
    this.summary = '',
    this.photoIds = const [],
    this.publishAt,
    required this.updatedAt,
  });

  bool get isEmpty => summary.isEmpty && photoIds.isEmpty;
}

/// Nouvelles en mémoire (dev sans serveur, tests), avec les règles de l'API :
/// un animateur ne voit que ses photos, la direction pioche dans toutes, un
/// jour par date du séjour, une photo par jour au plus, pas de jour vide
/// publié, et la visibilité jugée à l'heure de la lecture.
class InMemoryNewsRepository implements NewsRepository {
  final NewsViewer Function() _viewer;
  final StaffRole? Function(String stayId, String accountId) _roleOf;
  final Stay? Function(String stayId) _stayOf;
  final PhotoAuthor? Function(String accountId) _authorOf;
  final DateTime Function() _now;
  final List<_Photo> _photos = [];
  final List<_Day> _days = [];
  int _created = 0;

  /// Avec [demo], quelques photos et jours pour l'été 2027 de démo.
  InMemoryNewsRepository({
    required NewsViewer Function() viewer,
    required StaffRole? Function(String stayId, String accountId) roleOf,
    required Stay? Function(String stayId) stayOf,
    PhotoAuthor? Function(String accountId)? authorOf,
    DateTime Function()? now,
    bool demo = false,
  }) : _viewer = viewer,
       _roleOf = roleOf,
       _stayOf = stayOf,
       _authorOf = authorOf ?? ((_) => null),
       _now = now ?? DateTime.now {
    if (demo) _seed();
  }

  /// L'été 2027 de démo, et son directeur, Dominique Durand.
  static const demoStayId = '5d1e0000-0000-4000-8000-000000000001';
  static const _demoAuthorId = '0a5c0000-0000-4000-8000-000000000101';

  void _seed() {
    final now = _now();
    const sortings = [
      PhotoSorting.kept,
      PhotoSorting.kept,
      PhotoSorting.kept,
      PhotoSorting.pending,
      PhotoSorting.pending,
      PhotoSorting.discarded,
    ];
    for (final (index, sorting) in sortings.indexed) {
      _photos.add(
        _Photo(
          id: '9b0f0000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
          stayId: demoStayId,
          authorId: _demoAuthorId,
          uploadedAt: now.subtract(Duration(hours: 30 - index)),
          bytes: DemoPhotos.scene(index),
          sorting: sorting,
        ),
      );
    }
    String photo(int n) => _photos[n].id;
    _days.addAll([
      _Day(
        id: 'da500000-0000-4000-8000-000000000001',
        stayId: demoStayId,
        date: DateTime.utc(2027, 7, 10),
        summary:
            'Tout le monde est bien arrivé ! Installation dans les chambres, '
            'tour du domaine et premier grand jeu avant le dîner.',
        photoIds: [photo(0), photo(1)],
        publishAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      _Day(
        id: 'da500000-0000-4000-8000-000000000002',
        stayId: demoStayId,
        date: DateTime.utc(2027, 7, 11),
        summary: 'Randonnée jusqu\'au lac, pique-nique et baignade.',
        photoIds: [photo(2)],
        publishAt: now.add(const Duration(days: 1)),
        updatedAt: now,
      ),
      _Day(
        id: 'da500000-0000-4000-8000-000000000003',
        stayId: demoStayId,
        date: DateTime.utc(2027, 7, 12),
        summary: 'Veillée autour du feu.',
        updatedAt: now,
      ),
    ]);
  }

  @override
  Future<List<StayPhoto>> photos(String stayId) async {
    final access = _access(stayId);
    final me = _viewer().id;
    return [
      for (final photo in _photos)
        if (photo.stayId == stayId &&
            (access.direction || photo.authorId == me))
          _view(photo),
    ]..sort(comparePhotosForPick);
  }

  @override
  Future<StayPhoto> upload(String stayId, PickedPhoto photo) async {
    _access(stayId);
    if (photo.bytes.isEmpty) {
      throw const NewsException(NewsErrorCode.unsupportedPhoto);
    }
    final stored = _Photo(
      id: '9b0f0000-0000-4000-8000-${(++_created).toString().padLeft(12, '9')}',
      stayId: stayId,
      authorId: _viewer().id,
      uploadedAt: _now(),
      bytes: photo.bytes,
    );
    _photos.add(stored);
    return _view(stored);
  }

  @override
  Future<StayPhoto> sort(
    String stayId,
    String photoId,
    PhotoSorting sorting,
  ) async {
    final photo = _handled(stayId, photoId);
    photo.sorting = sorting;
    return _view(photo);
  }

  @override
  Future<void> deletePhoto(String stayId, String photoId) async {
    final photo = _handled(stayId, photoId);
    _photos.remove(photo);
    for (final day in _days) {
      day.photoIds = [...day.photoIds]..remove(photo.id);
    }
  }

  @override
  Future<Uint8List> image(String stayId, String photoId, PhotoSize size) async {
    final access = _access(stayId);
    final photo = _photoOf(stayId, photoId);
    final published = _days.any(
      (day) =>
          day.photoIds.contains(photoId) && _status(day) == DayStatus.published,
    );
    if (!access.direction && photo.authorId != _viewer().id && !published) {
      throw const NewsException(NewsErrorCode.photoNotFound);
    }
    return photo.bytes;
  }

  @override
  Future<List<NewsDay>> days(String stayId) async {
    _direction(stayId);
    return [
      for (final day in _days)
        if (day.stayId == stayId) _dayView(day),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<NewsDay> createDay(
    String stayId,
    DateTime date, {
    String summary = '',
  }) async {
    _direction(stayId);
    _requireFreeDate(stayId, date, exceptId: null);
    final day = _Day(
      id: 'da500000-0000-4000-8000-${(++_created).toString().padLeft(12, '9')}',
      stayId: stayId,
      date: date,
      summary: summary.trim(),
      updatedAt: _now(),
    );
    _days.add(day);
    return _dayView(day);
  }

  @override
  Future<NewsDay> updateDay(
    String stayId,
    String dayId, {
    required DateTime date,
    required String summary,
  }) async {
    final day = _dayOf(stayId, dayId);
    _requireFreeDate(stayId, date, exceptId: dayId);
    if (day.publishAt != null &&
        summary.trim().isEmpty &&
        day.photoIds.isEmpty) {
      throw const NewsException(NewsErrorCode.emptyDay);
    }
    day
      ..date = date
      ..summary = summary.trim()
      ..updatedAt = _now();
    return _dayView(day);
  }

  @override
  Future<void> deleteDay(String stayId, String dayId) async =>
      _days.remove(_dayOf(stayId, dayId));

  @override
  Future<NewsDay> setDayPhotos(
    String stayId,
    String dayId,
    List<String> photoIds,
  ) async {
    final day = _dayOf(stayId, dayId);
    for (final id in photoIds) {
      _photoOf(stayId, id);
      if (_days.any((other) => other != day && other.photoIds.contains(id))) {
        throw const NewsException(NewsErrorCode.photoInAnotherDay);
      }
    }
    if (photoIds.toSet().length != photoIds.length) {
      throw const NewsException(NewsErrorCode.unknown);
    }
    if (day.publishAt != null && day.summary.isEmpty && photoIds.isEmpty) {
      throw const NewsException(NewsErrorCode.emptyDay);
    }
    day
      ..photoIds = [...photoIds]
      ..updatedAt = _now();
    return _dayView(day);
  }

  @override
  Future<NewsDay> publishDay(
    String stayId,
    String dayId, {
    DateTime? at,
  }) async {
    final day = _dayOf(stayId, dayId);
    if (day.isEmpty) throw const NewsException(NewsErrorCode.emptyDay);
    final now = _now();
    day
      ..publishAt = at == null || !at.isAfter(now) ? now : at
      ..updatedAt = now;
    return _dayView(day);
  }

  @override
  Future<NewsDay> unpublishDay(String stayId, String dayId) async {
    final day = _dayOf(stayId, dayId);
    day
      ..publishAt = null
      ..updatedAt = _now();
    return _dayView(day);
  }

  @override
  Future<List<PublishedDay>> news(String stayId) async {
    _access(stayId);
    return [
      for (final day in _days)
        if (day.stayId == stayId && _status(day) == DayStatus.published)
          PublishedDay(
            id: day.id,
            date: day.date,
            summary: day.summary,
            publishedAt: day.publishAt!,
            photoIds: day.photoIds,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Le lien du compte connecté avec le séjour : comme l'API, le séjour
  /// n'existe pas pour qui n'y a aucun lien.
  ({bool direction}) _access(String stayId) {
    final viewer = _viewer();
    final role = _roleOf(stayId, viewer.id);
    if (_stayOf(stayId) == null || (!viewer.isAdmin && role == null)) {
      throw const NewsException(NewsErrorCode.stayNotFound);
    }
    return (
      direction:
          viewer.isAdmin ||
          role == StaffRole.director ||
          role == StaffRole.deputy,
    );
  }

  void _direction(String stayId) {
    if (!_access(stayId).direction) {
      throw const NewsException(NewsErrorCode.forbidden);
    }
  }

  _Photo _photoOf(String stayId, String photoId) =>
      _photos
          .where((photo) => photo.id == photoId && photo.stayId == stayId)
          .firstOrNull ??
      (throw const NewsException(NewsErrorCode.photoNotFound));

  /// Une photo que le compte peut trier : la sienne, ou toutes pour la
  /// direction.
  _Photo _handled(String stayId, String photoId) {
    final access = _access(stayId);
    final photo = _photoOf(stayId, photoId);
    if (!access.direction && photo.authorId != _viewer().id) {
      throw const NewsException(NewsErrorCode.photoNotFound);
    }
    return photo;
  }

  _Day _dayOf(String stayId, String dayId) {
    _direction(stayId);
    return _days
            .where((day) => day.id == dayId && day.stayId == stayId)
            .firstOrNull ??
        (throw const NewsException(NewsErrorCode.dayNotFound));
  }

  void _requireFreeDate(
    String stayId,
    DateTime date, {
    required String? exceptId,
  }) {
    final stay = _stayOf(stayId)!;
    if (date.isBefore(stay.startsOn) || date.isAfter(stay.endsOn)) {
      throw const NewsException(NewsErrorCode.invalidDayDate);
    }
    if (_days.any(
      (day) => day.stayId == stayId && day.id != exceptId && day.date == date,
    )) {
      throw const NewsException(NewsErrorCode.dayAlreadyExists);
    }
  }

  DayStatus _status(_Day day) => switch (day.publishAt) {
    null => DayStatus.draft,
    final at when at.isAfter(_now()) => DayStatus.scheduled,
    _ => DayStatus.published,
  };

  StayPhoto _view(_Photo photo) {
    final day = _days
        .where((day) => day.photoIds.contains(photo.id))
        .firstOrNull;
    return StayPhoto(
      id: photo.id,
      sorting: photo.sorting,
      uploadedAt: photo.uploadedAt,
      author: _authorOf(photo.authorId),
      mine: photo.authorId == _viewer().id,
      dayId: day?.id,
      dayDate: day?.date,
    );
  }

  NewsDay _dayView(_Day day) => NewsDay(
    id: day.id,
    date: day.date,
    summary: day.summary,
    status: _status(day),
    publishAt: day.publishAt,
    photoIds: day.photoIds,
    updatedAt: day.updatedAt,
  );
}
