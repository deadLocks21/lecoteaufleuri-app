import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/infrastructure/questions/dio.questions.repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  const stay = '5d1e0000-0000-4000-8000-000000000001';
  const threadJson = {
    'id': 'q1',
    'category_id': 'c1',
    'title': 'Peut-on veiller ?',
    'body': 'Le soir du feu de camp.',
    'visibility': 'public',
    'anonymous': true,
    'author': null,
    'mine': false,
    'resolved_at': null,
    'created_at': '2027-07-12T12:00:00+00:00',
    'updated_at': '2027-07-12T12:00:00+00:00',
    'deleted_at': null,
    'reply_count': 1,
    'last_activity_at': '2027-07-12T12:05:00+00:00',
    'replies': [
      {
        'id': 'r1',
        'body': 'Jusqu\'à 23 h.',
        'author': {
          'id': 'a1',
          'first_name': 'Dominique',
          'last_name': 'Durand',
        },
        'mine': false,
        'created_at': '2027-07-12T12:05:00+00:00',
        'updated_at': '2027-07-12T12:05:00+00:00',
        'deleted_at': null,
      },
    ],
  };

  Matcher failsWith(QuestionsErrorCode expected) => throwsA(
    isA<QuestionsException>().having((e) => e.code, 'code', expected),
  );

  test('lit une question anonyme et son fil', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(threadJson));

    final question = await DioQuestionsRepository(
      dioWith(adapter),
    ).question(stay, 'q1');

    expect(adapter.requests.single.path, '/api/stays/$stay/questions/q1');
    expect(question.visibility, QuestionVisibility.public);
    expect(question.anonymous, isTrue);
    expect(question.author, isNull);
    expect(question.replies!.single.author!.firstName, 'Dominique');
  });

  test('pose une question privée, dans une catégorie', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        ...threadJson,
        'visibility': 'private',
        'anonymous': false,
      }, status: 201),
    );

    await DioQuestionsRepository(
      dioWith(adapter),
    ).ask(stay, title: 'Peut-on veiller ?', categoryId: 'c1');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/api/stays/$stay/questions');
    expect(jsonDecode(jsonEncode(request.data)), {
      'title': 'Peut-on veiller ?',
      'body': '',
      'category_id': 'c1',
      'visibility': 'private',
    });
  });

  test('rend publique en taisant le nom de l\'auteur', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(threadJson));

    await DioQuestionsRepository(
      dioWith(adapter),
    ).show(stay, 'q1', QuestionVisibility.public, anonymous: true);

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/api/stays/$stay/questions/q1/visibility');
    expect(request.data, {'visibility': 'public', 'anonymous': true});
  });

  test('traduit les codes d\'erreur de l\'API', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json({
        'error': '…',
        'code': 'category_already_exists',
      }, status: 409),
    );

    expect(
      DioQuestionsRepository(dioWith(adapter)).createCategory(stay, 'Sécurité'),
      failsWith(QuestionsErrorCode.categoryAlreadyExists),
    );
  });

  test('un corps qui n\'a pas la forme d\'une question est refusé', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({'id': 'q1'}));

    expect(
      DioQuestionsRepository(dioWith(adapter)).question(stay, 'q1'),
      failsWith(QuestionsErrorCode.badServerUrl),
    );
  });
}
