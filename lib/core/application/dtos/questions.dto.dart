import 'package:lecoteaufleuri/core/domain/model/questions.dart';

/// Une réponse du fil, telle que l'UI l'affiche.
class QuestionReplyDto {
  final String id;
  final String body;

  /// `Prénom Nom` de qui l'a écrite ; null si l'API le tait ou si le compte
  /// a disparu.
  final String? authorName;
  final bool mine;
  final DateTime createdAt;
  final bool edited;
  final bool deleted;

  const QuestionReplyDto({
    required this.id,
    required this.body,
    this.authorName,
    required this.mine,
    required this.createdAt,
    this.edited = false,
    this.deleted = false,
  });

  factory QuestionReplyDto.fromDomain(QuestionReply reply) => QuestionReplyDto(
    id: reply.id,
    body: reply.body,
    authorName: _name(reply.author),
    mine: reply.mine,
    createdAt: reply.createdAt,
    edited: reply.updatedAt.isAfter(reply.createdAt),
    deleted: reply.deletedAt != null,
  );
}

/// Une question, telle que l'UI l'affiche : dans la liste (sans [replies])
/// ou ouverte, avec son fil.
class QuestionDto {
  final String id;
  final String? categoryId;
  final String title;
  final String body;
  final QuestionVisibility visibility;
  final bool anonymous;

  /// `Prénom Nom` de qui l'a posée ; null si l'API le tait (question anonyme)
  /// ou si le compte a disparu.
  final String? authorName;
  final String? authorId;
  final bool mine;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final bool edited;
  final DateTime? deletedAt;
  final int replyCount;
  final DateTime lastActivityAt;
  final List<QuestionReplyDto>? replies;

  const QuestionDto({
    required this.id,
    this.categoryId,
    required this.title,
    this.body = '',
    required this.visibility,
    this.anonymous = false,
    this.authorName,
    this.authorId,
    required this.mine,
    this.resolvedAt,
    required this.createdAt,
    this.edited = false,
    this.deletedAt,
    this.replyCount = 0,
    required this.lastActivityAt,
    this.replies,
  });

  factory QuestionDto.fromDomain(Question question) => QuestionDto(
    id: question.id,
    categoryId: question.categoryId,
    title: question.title,
    body: question.body,
    visibility: question.visibility,
    anonymous: question.anonymous,
    authorName: _name(question.author),
    authorId: question.author?.id,
    mine: question.mine,
    resolvedAt: question.resolvedAt,
    createdAt: question.createdAt,
    edited: question.updatedAt.isAfter(question.createdAt),
    deletedAt: question.deletedAt,
    replyCount: question.replyCount,
    lastActivityAt: question.lastActivityAt,
    replies: switch (question.replies) {
      final List<QuestionReply> replies => [
        for (final reply in replies) QuestionReplyDto.fromDomain(reply),
      ],
      null => null,
    },
  );

  bool get isPublic => visibility == QuestionVisibility.public;
  bool get isResolved => resolvedAt != null;
  bool get isDeleted => deletedAt != null;

  /// La même question, sans son fil : la forme d'une liste.
  QuestionDto get summary => QuestionDto(
    id: id,
    categoryId: categoryId,
    title: title,
    body: body,
    visibility: visibility,
    anonymous: anonymous,
    authorName: authorName,
    authorId: authorId,
    mine: mine,
    resolvedAt: resolvedAt,
    createdAt: createdAt,
    edited: edited,
    deletedAt: deletedAt,
    replyCount: replyCount,
    lastActivityAt: lastActivityAt,
  );
}

class QuestionCategoryDto {
  final String id;
  final String name;

  const QuestionCategoryDto({required this.id, required this.name});

  factory QuestionCategoryDto.fromDomain(QuestionCategory category) =>
      QuestionCategoryDto(id: category.id, name: category.name);
}

String? _name(QuestionAuthor? author) => switch (author) {
  final QuestionAuthor a => '${a.firstName} ${a.lastName}'.trim(),
  null => null,
};
