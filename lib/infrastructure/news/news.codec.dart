import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

/// Formes JSON des nouvelles d'un séjour, celles de l'API (cf. `API.md` du
/// dépôt api) : jours au format `AAAA-MM-JJ`, heures en ISO 8601.
abstract final class NewsCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static StayPhoto photoFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'sorting': final String sorting,
      'uploaded_at': final String uploadedAt,
      'mine': final bool mine,
    } when id.isNotEmpty) {
      final day = json['day'];
      return StayPhoto(
        id: id,
        sorting: sortingFromJson(sorting),
        uploadedAt: _instant(uploadedAt),
        author: switch (json['author']) {
          {
            'id': final String id,
            'first_name': final String firstName,
            'last_name': final String lastName,
          } =>
            PhotoAuthor(id: id, firstName: firstName, lastName: lastName),
          null => null,
          _ => throw const FormatException('Photo author JSON is malformed'),
        },
        mine: mine,
        dayId: switch (day) {
          {'id': final String id} => id,
          null => null,
          _ => throw const FormatException('Photo day JSON is malformed'),
        },
        dayDate: switch (day) {
          {'date': final String date} => StayCodec.parseDay(date),
          _ => null,
        },
      );
    }
    throw const FormatException('Photo JSON is malformed');
  }

  static PhotoSorting sortingFromJson(String value) => switch (value) {
    'pending' => PhotoSorting.pending,
    'kept' => PhotoSorting.kept,
    'discarded' => PhotoSorting.discarded,
    _ => throw FormatException('Unknown photo sorting', value),
  };

  static String sortingToJson(PhotoSorting sorting) => sorting.name;

  static NewsDay dayFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'date': final String date,
      'summary': final String summary,
      'status': final String status,
      'photo_ids': final List<Object?> photoIds,
      'updated_at': final String updatedAt,
    } when id.isNotEmpty) {
      return NewsDay(
        id: id,
        date: StayCodec.parseDay(date),
        summary: summary,
        status: switch (status) {
          'draft' => DayStatus.draft,
          'scheduled' => DayStatus.scheduled,
          'published' => DayStatus.published,
          _ => throw FormatException('Unknown day status', status),
        },
        publishAt: switch (json['publish_at']) {
          final String at => _instant(at),
          null => null,
          _ => throw const FormatException('Day publish_at is malformed'),
        },
        photoIds: _ids(photoIds),
        updatedAt: _instant(updatedAt),
      );
    }
    throw const FormatException('Day JSON is malformed');
  }

  static PublishedDay publishedFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'date': final String date,
      'summary': final String summary,
      'published_at': final String publishedAt,
      'photo_ids': final List<Object?> photoIds,
    } when id.isNotEmpty) {
      return PublishedDay(
        id: id,
        date: StayCodec.parseDay(date),
        summary: summary,
        publishedAt: _instant(publishedAt),
        photoIds: _ids(photoIds),
      );
    }
    throw const FormatException('Published day JSON is malformed');
  }

  /// Une heure à envoyer : ISO 8601 en UTC.
  static String instantToJson(DateTime at) => at.toUtc().toIso8601String();

  static DateTime _instant(String value) {
    final instant = DateTime.tryParse(value);
    if (instant == null) throw FormatException('Not an instant', value);
    return instant.toUtc();
  }

  static List<String> _ids(List<Object?> ids) => [
    for (final id in ids)
      if (id is String && id.isNotEmpty)
        id
      else
        throw const FormatException('Photo id is malformed'),
  ];
}
