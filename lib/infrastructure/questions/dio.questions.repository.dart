import 'package:dio/dio.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/services/questions.repository.dart';
import 'package:lecoteaufleuri/infrastructure/http/api_endpoints.dart';
import 'package:lecoteaufleuri/infrastructure/http/error_code.dart';
import 'package:lecoteaufleuri/infrastructure/questions/questions.codec.dart';

/// [QuestionsRepository] sur HTTP : `/api/stays/{id}/questions…` (cf.
/// `API.md` du dépôt api). Toute erreur devient une [QuestionsException].
class DioQuestionsRepository implements QuestionsRepository {
  final Dio _dio;

  DioQuestionsRepository(this._dio);

  @override
  Future<List<Question>> questions(String stayId) async =>
      _questions(await _send('GET', ApiEndpoints.stayQuestions(stayId)));

  @override
  Future<List<Question>> deleted(String stayId) async => _questions(
    await _send('GET', '${ApiEndpoints.stayQuestions(stayId)}/deleted'),
  );

  @override
  Future<Question> question(String stayId, String questionId) async =>
      _question(
        await _send('GET', ApiEndpoints.stayQuestion(stayId, questionId)),
      );

  @override
  Future<Question> ask(
    String stayId, {
    required String title,
    String body = '',
    String? categoryId,
    QuestionVisibility visibility = QuestionVisibility.private,
  }) async => _question(
    await _send(
      'POST',
      ApiEndpoints.stayQuestions(stayId),
      data: {
        'title': title,
        'body': body,
        'category_id': ?categoryId,
        'visibility': visibility.name,
      },
    ),
  );

  @override
  Future<Question> edit(
    String stayId,
    String questionId, {
    required String title,
    String body = '',
  }) async => _question(
    await _send(
      'PUT',
      ApiEndpoints.stayQuestion(stayId, questionId),
      data: {'title': title, 'body': body},
    ),
  );

  @override
  Future<Question> classify(
    String stayId,
    String questionId,
    String? categoryId,
  ) async => _question(
    await _send(
      'PUT',
      '${ApiEndpoints.stayQuestion(stayId, questionId)}/category',
      data: {'category_id': categoryId},
    ),
  );

  @override
  Future<Question> show(
    String stayId,
    String questionId,
    QuestionVisibility visibility, {
    bool anonymous = false,
  }) async => _question(
    await _send(
      'PUT',
      '${ApiEndpoints.stayQuestion(stayId, questionId)}/visibility',
      data: {'visibility': visibility.name, 'anonymous': anonymous},
    ),
  );

  @override
  Future<Question> resolve(
    String stayId,
    String questionId,
    bool resolved,
  ) async => _question(
    await _send(
      'PUT',
      '${ApiEndpoints.stayQuestion(stayId, questionId)}/resolution',
      data: {'resolved': resolved},
    ),
  );

  @override
  Future<void> delete(String stayId, String questionId) =>
      _send('DELETE', ApiEndpoints.stayQuestion(stayId, questionId));

  @override
  Future<Question> restore(String stayId, String questionId) async => _question(
    await _send(
      'POST',
      '${ApiEndpoints.stayQuestion(stayId, questionId)}/restore',
    ),
  );

  @override
  Future<void> purge(String stayId, String questionId) => _send(
    'DELETE',
    '${ApiEndpoints.stayQuestion(stayId, questionId)}/permanent',
  );

  @override
  Future<Question> reply(String stayId, String questionId, String body) async =>
      _question(
        await _send(
          'POST',
          '${ApiEndpoints.stayQuestion(stayId, questionId)}/replies',
          data: {'body': body},
        ),
      );

  @override
  Future<Question> editReply(
    String stayId,
    String questionId,
    String replyId,
    String body,
  ) async => _question(
    await _send(
      'PUT',
      ApiEndpoints.stayQuestionReply(stayId, questionId, replyId),
      data: {'body': body},
    ),
  );

  @override
  Future<Question> deleteReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => _question(
    await _send(
      'DELETE',
      ApiEndpoints.stayQuestionReply(stayId, questionId, replyId),
    ),
  );

  @override
  Future<Question> restoreReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => _question(
    await _send(
      'POST',
      '${ApiEndpoints.stayQuestionReply(stayId, questionId, replyId)}/restore',
    ),
  );

  @override
  Future<Question> purgeReply(
    String stayId,
    String questionId,
    String replyId,
  ) async => _question(
    await _send(
      'DELETE',
      '${ApiEndpoints.stayQuestionReply(stayId, questionId, replyId)}/permanent',
    ),
  );

  @override
  Future<List<QuestionCategory>> categories(String stayId) async {
    final body = await _send(
      'GET',
      ApiEndpoints.stayQuestionCategories(stayId),
    );
    return switch (body?['categories']) {
      final List<Object?> list => [
        for (final item in list) _decode(QuestionsCodec.categoryFromJson, item),
      ],
      _ => throw const QuestionsException(QuestionsErrorCode.badServerUrl),
    };
  }

  @override
  Future<QuestionCategory> createCategory(String stayId, String name) async =>
      _category(
        await _send(
          'POST',
          ApiEndpoints.stayQuestionCategories(stayId),
          data: {'name': name},
        ),
      );

  @override
  Future<QuestionCategory> renameCategory(
    String stayId,
    String categoryId,
    String name,
  ) async => _category(
    await _send(
      'PUT',
      ApiEndpoints.stayQuestionCategory(stayId, categoryId),
      data: {'name': name},
    ),
  );

  @override
  Future<void> deleteCategory(String stayId, String categoryId) =>
      _send('DELETE', ApiEndpoints.stayQuestionCategory(stayId, categoryId));

  static List<Question> _questions(Map<String, dynamic>? body) =>
      switch (body?['questions']) {
        final List<Object?> list => [
          for (final item in list)
            _decode(QuestionsCodec.questionFromJson, item),
        ],
        _ => throw const QuestionsException(QuestionsErrorCode.badServerUrl),
      };

  static Question _question(Map<String, dynamic>? body) =>
      _decode(QuestionsCodec.questionFromJson, body);

  static QuestionCategory _category(Map<String, dynamic>? body) =>
      _decode(QuestionsCodec.categoryFromJson, body);

  static T _decode<T>(T Function(Object?) decode, Object? json) {
    try {
      return decode(json);
    } on FormatException {
      throw const QuestionsException(QuestionsErrorCode.badServerUrl);
    }
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Object? data,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method),
      );
      return switch (response.data) {
        final Map<String, dynamic> body => body,
        null || '' when response.statusCode == 204 => null,
        _ => throw const QuestionsException(QuestionsErrorCode.badServerUrl),
      };
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  static QuestionsException _mapError(DioException e) {
    final response = e.response;
    if (response == null) {
      return const QuestionsException(QuestionsErrorCode.network);
    }
    final data = response.data;
    if (data is String && data.trim().isNotEmpty) {
      return const QuestionsException(QuestionsErrorCode.badServerUrl);
    }
    return QuestionsException(switch (readErrorCode(response)) {
      'forbidden' => QuestionsErrorCode.forbidden,
      'stay_not_found' => QuestionsErrorCode.stayNotFound,
      'question_not_found' => QuestionsErrorCode.questionNotFound,
      'reply_not_found' => QuestionsErrorCode.replyNotFound,
      'category_not_found' => QuestionsErrorCode.categoryNotFound,
      'invalid_question' => QuestionsErrorCode.invalidQuestion,
      'invalid_reply' => QuestionsErrorCode.invalidReply,
      'invalid_category' => QuestionsErrorCode.invalidCategory,
      'category_already_exists' => QuestionsErrorCode.categoryAlreadyExists,
      'invalid_token' => QuestionsErrorCode.sessionExpired,
      _ => QuestionsErrorCode.unknown,
    });
  }
}
