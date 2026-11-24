import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/application/usecases/questions.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/infrastructure/providers/questions.service_provider.dart';
import 'package:lecoteaufleuri/infrastructure/providers/stay_questions.controller_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'question_thread.controller_provider.g.dart';

/// Une question ouverte, avec son fil, et ce qu'on y fait. Chaque action
/// rend null, ou la raison de l'échec ; la liste des questions suit.
@riverpod
class QuestionThreadController extends _$QuestionThreadController {
  QuestionThreadUseCase get _thread =>
      ref.read(questionsServiceProvider).thread;

  @override
  Future<QuestionDto> build(String stayId, String questionId) =>
      ref.watch(questionsServiceProvider).thread.get(stayId, questionId);

  Future<QuestionsErrorCode?> edit({required String title, String body = ''}) =>
      _run(() => _thread.edit(stayId, questionId, title: title, body: body));

  Future<QuestionsErrorCode?> classify(String? categoryId) =>
      _run(() => _thread.classify(stayId, questionId, categoryId));

  Future<QuestionsErrorCode?> show(
    QuestionVisibility visibility, {
    bool anonymous = false,
  }) => _run(
    () => _thread.show(stayId, questionId, visibility, anonymous: anonymous),
  );

  Future<QuestionsErrorCode?> resolve(bool resolved) =>
      _run(() => _thread.resolve(stayId, questionId, resolved));

  Future<QuestionsErrorCode?> delete() => _run(() async {
    await _thread.delete(stayId, questionId);
    return null;
  });

  Future<QuestionsErrorCode?> restore() =>
      _run(() => _thread.restore(stayId, questionId), restored: true);

  Future<QuestionsErrorCode?> purge() => _run(() async {
    await _thread.purge(stayId, questionId);
    return null;
  });

  Future<QuestionsErrorCode?> reply(String body) =>
      _run(() => _thread.reply(stayId, questionId, body));

  Future<QuestionsErrorCode?> editReply(String replyId, String body) =>
      _run(() => _thread.editReply(stayId, questionId, replyId, body));

  Future<QuestionsErrorCode?> deleteReply(String replyId) =>
      _run(() => _thread.deleteReply(stayId, questionId, replyId));

  Future<QuestionsErrorCode?> restoreReply(String replyId) =>
      _run(() => _thread.restoreReply(stayId, questionId, replyId));

  Future<QuestionsErrorCode?> purgeReply(String replyId) =>
      _run(() => _thread.purgeReply(stayId, questionId, replyId));

  /// [action] rend la question changée, ou null quand elle quitte la liste
  /// (supprimée, effacée).
  Future<QuestionsErrorCode?> _run(
    Future<QuestionDto?> Function() action, {
    bool restored = false,
  }) async {
    try {
      final question = await action();
      if (!ref.mounted) return null;
      final list = ref.read(stayQuestionsControllerProvider(stayId).notifier);
      if (question == null) {
        list.remove(questionId);
        ref.invalidate(deletedQuestionsProvider(stayId));
      } else {
        state = AsyncData(question);
        if (!question.isDeleted) list.upsert(question);
        if (restored) ref.invalidate(deletedQuestionsProvider(stayId));
      }
      return null;
    } on QuestionsException catch (e) {
      if (const {
            QuestionsErrorCode.questionNotFound,
            QuestionsErrorCode.replyNotFound,
            QuestionsErrorCode.forbidden,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
        ref.invalidate(stayQuestionsControllerProvider(stayId));
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('question : échec inattendu : $e\n$stack');
      return QuestionsErrorCode.unknown;
    }
  }
}
