import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/services/questions.repository.dart';

/// Les questions du séjour, sans leur fil (ou les supprimées, pour la
/// direction).
class ListQuestionsUseCase {
  final QuestionsRepository _questions;

  ListQuestionsUseCase(this._questions);

  Future<List<QuestionDto>> execute(String stayId) async => [
    for (final q in await _questions.questions(stayId))
      QuestionDto.fromDomain(q),
  ];

  Future<List<QuestionDto>> deleted(String stayId) async => [
    for (final q in await _questions.deleted(stayId)) QuestionDto.fromDomain(q),
  ];
}

/// Une question et son fil, et tout ce qu'on y fait : la poser, la modifier,
/// la classer, la montrer, la résoudre, la supprimer ; y répondre.
class QuestionThreadUseCase {
  final QuestionsRepository _questions;

  QuestionThreadUseCase(this._questions);

  Future<QuestionDto> get(String stayId, String questionId) async =>
      QuestionDto.fromDomain(await _questions.question(stayId, questionId));

  Future<QuestionDto> ask(
    String stayId, {
    required String title,
    String body = '',
    String? categoryId,
    QuestionVisibility visibility = QuestionVisibility.private,
  }) async => QuestionDto.fromDomain(
    await _questions.ask(
      stayId,
      title: title,
      body: body,
      categoryId: categoryId,
      visibility: visibility,
    ),
  );

  Future<QuestionDto> edit(
    String stayId,
    String questionId, {
    required String title,
    String body = '',
  }) async => QuestionDto.fromDomain(
    await _questions.edit(stayId, questionId, title: title, body: body),
  );

  Future<QuestionDto> classify(
    String stayId,
    String questionId,
    String? categoryId,
  ) async => QuestionDto.fromDomain(
    await _questions.classify(stayId, questionId, categoryId),
  );

  Future<QuestionDto> show(
    String stayId,
    String questionId,
    QuestionVisibility visibility, {
    bool anonymous = false,
  }) async => QuestionDto.fromDomain(
    await _questions.show(stayId, questionId, visibility, anonymous: anonymous),
  );

  Future<QuestionDto> resolve(
    String stayId,
    String questionId,
    bool resolved,
  ) async => QuestionDto.fromDomain(
    await _questions.resolve(stayId, questionId, resolved),
  );

  Future<void> delete(String stayId, String questionId) =>
      _questions.delete(stayId, questionId);

  Future<QuestionDto> restore(String stayId, String questionId) async =>
      QuestionDto.fromDomain(await _questions.restore(stayId, questionId));

  Future<void> purge(String stayId, String questionId) =>
      _questions.purge(stayId, questionId);

  Future<QuestionDto> reply(
    String stayId,
    String questionId,
    String body,
  ) async =>
      QuestionDto.fromDomain(await _questions.reply(stayId, questionId, body));

  Future<QuestionDto> editReply(
    String stayId,
    String questionId,
    String replyId,
    String body,
  ) async => QuestionDto.fromDomain(
    await _questions.editReply(stayId, questionId, replyId, body),
  );

  Future<QuestionDto> deleteReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => QuestionDto.fromDomain(
    await _questions.deleteReply(stayId, questionId, replyId),
  );

  Future<QuestionDto> restoreReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => QuestionDto.fromDomain(
    await _questions.restoreReply(stayId, questionId, replyId),
  );

  Future<QuestionDto> purgeReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => QuestionDto.fromDomain(
    await _questions.purgeReply(stayId, questionId, replyId),
  );
}

/// Les catégories du séjour : toute l'équipe les lit, la direction les gère.
class QuestionCategoriesUseCase {
  final QuestionsRepository _questions;

  QuestionCategoriesUseCase(this._questions);

  Future<List<QuestionCategoryDto>> list(String stayId) async => [
    for (final c in await _questions.categories(stayId))
      QuestionCategoryDto.fromDomain(c),
  ];

  Future<QuestionCategoryDto> create(String stayId, String name) async =>
      QuestionCategoryDto.fromDomain(
        await _questions.createCategory(stayId, name),
      );

  Future<QuestionCategoryDto> rename(
    String stayId,
    String categoryId,
    String name,
  ) async => QuestionCategoryDto.fromDomain(
    await _questions.renameCategory(stayId, categoryId, name),
  );

  Future<void> delete(String stayId, String categoryId) =>
      _questions.deleteCategory(stayId, categoryId);
}
