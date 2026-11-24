import 'package:flutter/foundation.dart';
import 'package:lecoteaufleuri/core/application/dtos/questions.dto.dart';
import 'package:lecoteaufleuri/core/application/services/questions_application.service.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/infrastructure/providers/questions.service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stay_questions.controller_provider.g.dart';

/// Ce que rend une action : la question (avec son fil), ou la raison de
/// l'échec.
typedef QuestionOutcome = ({QuestionDto? question, QuestionsErrorCode? error});

/// Les questions d'un séjour, sans leur fil (toutes pour la direction, les
/// publiques et les siennes pour un animateur), la plus récemment active
/// d'abord ; et poser une question.
@riverpod
class StayQuestionsController extends _$StayQuestionsController {
  QuestionsApplicationService get _service =>
      ref.read(questionsServiceProvider);

  @override
  Future<List<QuestionDto>> build(String stayId) =>
      ref.watch(questionsServiceProvider).list.execute(stayId);

  Future<QuestionOutcome> ask({
    required String title,
    String body = '',
    String? categoryId,
    QuestionVisibility visibility = QuestionVisibility.private,
  }) async {
    try {
      final question = await _service.thread.ask(
        stayId,
        title: title,
        body: body,
        categoryId: categoryId,
        visibility: visibility,
      );
      upsert(question);
      return (question: question, error: null);
    } on QuestionsException catch (e) {
      if (e.code == QuestionsErrorCode.categoryNotFound && ref.mounted) {
        ref.invalidate(questionCategoriesControllerProvider(stayId));
      }
      return (question: null, error: e.code);
    } catch (e, stack) {
      debugPrint('questions : échec inattendu : $e\n$stack');
      return (question: null, error: QuestionsErrorCode.unknown);
    }
  }

  /// La direction marque la question résolue, ou la rouvre, depuis la
  /// liste. Rend null, ou la raison de l'échec.
  Future<QuestionsErrorCode?> resolve(String questionId, bool resolved) async {
    try {
      upsert(await _service.thread.resolve(stayId, questionId, resolved));
      return null;
    } on QuestionsException catch (e) {
      if (const {
            QuestionsErrorCode.questionNotFound,
            QuestionsErrorCode.forbidden,
          }.contains(e.code) &&
          ref.mounted) {
        ref.invalidateSelf();
      }
      return e.code;
    } catch (e, stack) {
      debugPrint('questions : échec inattendu : $e\n$stack');
      return QuestionsErrorCode.unknown;
    }
  }

  /// La question (changée ailleurs, dans son fil) prend sa place, en tête.
  void upsert(QuestionDto question) {
    if (!ref.mounted || state.value == null) return;
    state = AsyncData(
      [
        question.summary,
        for (final other in state.value!)
          if (other.id != question.id) other,
      ]..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt)),
    );
  }

  void remove(String questionId) {
    if (!ref.mounted || state.value == null) return;
    state = AsyncData([
      for (final other in state.value!)
        if (other.id != questionId) other,
    ]);
  }
}

/// Les questions supprimées du séjour, que la direction restaure ou efface.
@riverpod
Future<List<QuestionDto>> deletedQuestions(Ref ref, String stayId) =>
    ref.watch(questionsServiceProvider).list.deleted(stayId);

/// Les catégories du séjour, par ordre alphabétique ; la direction les crée
/// à la volée, les renomme et les supprime.
@riverpod
class QuestionCategoriesController extends _$QuestionCategoriesController {
  QuestionsApplicationService get _service =>
      ref.read(questionsServiceProvider);

  @override
  Future<List<QuestionCategoryDto>> build(String stayId) =>
      ref.watch(questionsServiceProvider).categories.list(stayId);

  Future<({QuestionCategoryDto? category, QuestionsErrorCode? error})> create(
    String name,
  ) async {
    try {
      final category = await _service.categories.create(stayId, name);
      _put(category);
      return (category: category, error: null);
    } on QuestionsException catch (e) {
      return (category: null, error: e.code);
    }
  }

  Future<QuestionsErrorCode?> rename(String categoryId, String name) async {
    try {
      _put(await _service.categories.rename(stayId, categoryId, name));
      return null;
    } on QuestionsException catch (e) {
      return e.code;
    }
  }

  Future<QuestionsErrorCode?> delete(String categoryId) async {
    try {
      await _service.categories.delete(stayId, categoryId);
      if (ref.mounted) {
        state = AsyncData([
          for (final c in state.value ?? const <QuestionCategoryDto>[])
            if (c.id != categoryId) c,
        ]);
        // Ses questions n'ont plus de catégorie.
        ref.invalidate(stayQuestionsControllerProvider(stayId));
      }
      return null;
    } on QuestionsException catch (e) {
      return e.code;
    }
  }

  void _put(QuestionCategoryDto category) {
    if (!ref.mounted) return;
    state = AsyncData(
      [
        for (final c in state.value ?? const <QuestionCategoryDto>[])
          if (c.id != category.id) c,
        category,
      ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }
}
