import 'package:lecoteaufleuri/core/domain/model/questions.dart';

/// Forme JSON des questions, celle de l'API (cf. `API.md` du dépôt api).
abstract final class QuestionsCodec {
  /// Lève une [FormatException] si [json] n'a pas la forme attendue.
  static Question questionFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'title': final String title,
      'body': final String body,
      'visibility': final String visibility,
      'anonymous': final bool anonymous,
      'mine': final bool mine,
      'created_at': final String createdAt,
      'updated_at': final String updatedAt,
      'reply_count': final int replyCount,
      'last_activity_at': final String lastActivityAt,
    } when id.isNotEmpty) {
      return Question(
        id: id,
        categoryId: _optionalString(json['category_id']),
        title: title,
        body: body,
        visibility: visibilityFromName(visibility),
        anonymous: anonymous,
        author: _author(json['author']),
        mine: mine,
        resolvedAt: _optionalInstant(json['resolved_at']),
        createdAt: _instant(createdAt),
        updatedAt: _instant(updatedAt),
        deletedAt: _optionalInstant(json['deleted_at']),
        replyCount: replyCount,
        lastActivityAt: _instant(lastActivityAt),
        replies: switch (json['replies']) {
          null => null,
          final List<Object?> replies => [
            for (final reply in replies) _reply(reply),
          ],
          _ => throw const FormatException('Replies should be a list'),
        },
      );
    }
    throw const FormatException('Question JSON is malformed');
  }

  static QuestionCategory categoryFromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
    } when id.isNotEmpty) {
      return QuestionCategory(id: id, name: name);
    }
    throw const FormatException('Question category JSON is malformed');
  }

  static QuestionVisibility visibilityFromName(String name) =>
      QuestionVisibility.values.where((v) => v.name == name).firstOrNull ??
      (throw const FormatException('Unknown question visibility'));

  static QuestionReply _reply(Object? json) {
    if (json case {
      'id': final String id,
      'body': final String body,
      'mine': final bool mine,
      'created_at': final String createdAt,
      'updated_at': final String updatedAt,
    } when id.isNotEmpty) {
      return QuestionReply(
        id: id,
        body: body,
        author: _author(json['author']),
        mine: mine,
        createdAt: _instant(createdAt),
        updatedAt: _instant(updatedAt),
        deletedAt: _optionalInstant(json['deleted_at']),
      );
    }
    throw const FormatException('Question reply JSON is malformed');
  }

  static QuestionAuthor? _author(Object? json) => switch (json) {
    null => null,
    {
      'id': final String id,
      'first_name': final String firstName,
      'last_name': final String lastName,
    } =>
      QuestionAuthor(id: id, firstName: firstName, lastName: lastName),
    _ => throw const FormatException('Question author JSON is malformed'),
  };

  static String? _optionalString(Object? value) => switch (value) {
    null => null,
    final String text => text,
    _ => throw const FormatException('Expected a string or null'),
  };

  static DateTime? _optionalInstant(Object? value) => switch (value) {
    null => null,
    final String at => _instant(at),
    _ => throw const FormatException('Expected an instant or null'),
  };

  static DateTime _instant(String value) =>
      DateTime.tryParse(value) ??
      (throw const FormatException('Expected an ISO 8601 instant'));
}
