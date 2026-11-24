import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/questions.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/questions.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/questions/in_memory.questions.repository.dart';

/// Les règles de l'API, rejouées en mémoire (`ACCES.md`, « Questions du
/// séjour »).
void main() {
  const stay = 's1';
  const director = 'd1';
  const deputy = 'd2';
  const animator = 'a1';
  const other = 'a2';
  const roles = {
    director: StaffRole.director,
    deputy: StaffRole.deputy,
    animator: StaffRole.animator,
    other: StaffRole.animator,
  };

  late String me;
  late InMemoryQuestionsRepository questions;

  setUp(() {
    me = director;
    var tick = 0;
    questions = InMemoryQuestionsRepository(
      viewer: () => (id: me, isAdmin: false),
      roleOf: (stayId, id) => stayId == stay ? roles[id] : null,
      authorOf: (id) =>
          QuestionAuthor(id: id, firstName: 'Prénom $id', lastName: ''),
      now: () => DateTime.utc(2027, 7, 12, 12, tick++),
    );
  });

  Matcher failsWith(QuestionsErrorCode expected) => throwsA(
    isA<QuestionsException>().having((e) => e.code, 'code', expected),
  );

  test('une question privée de la direction reste entre directeurs et '
      'adjoints', () async {
    final q = await questions.ask(stay, title: 'Budget ?');

    me = deputy;
    expect(await questions.questions(stay), hasLength(1));
    me = animator;
    expect(await questions.questions(stay), isEmpty);
    expect(
      questions.question(stay, q.id),
      failsWith(QuestionsErrorCode.questionNotFound),
    );
  });

  test('un animateur ne publie pas et ne répond pas à la question d\'un '
      'autre', () async {
    me = animator;
    expect(
      questions.ask(
        stay,
        title: 'Public ?',
        visibility: QuestionVisibility.public,
      ),
      failsWith(QuestionsErrorCode.forbidden),
    );
    me = director;
    final q = await questions.ask(
      stay,
      title: 'Matériel ?',
      visibility: QuestionVisibility.public,
    );
    me = animator;
    expect(
      questions.reply(stay, q.id, 'Et moi ?'),
      failsWith(QuestionsErrorCode.forbidden),
    );
  });

  test('anonyme, la question tait son auteur aux autres animateurs '
      'seulement', () async {
    me = animator;
    final q = await questions.ask(stay, title: 'Veiller ?');
    await questions.reply(stay, q.id, 'Le soir du feu.');
    me = director;
    await questions.show(
      stay,
      q.id,
      QuestionVisibility.public,
      anonymous: true,
    );

    me = other;
    final seen = await questions.question(stay, q.id);
    expect(seen.author, isNull);
    expect(seen.replies!.single.author, isNull);
    me = deputy;
    expect((await questions.question(stay, q.id)).author?.id, animator);
  });

  test('la question de la direction reste nommée', () async {
    final q = await questions.ask(stay, title: 'Courses ?');
    final shown = await questions.show(
      stay,
      q.id,
      QuestionVisibility.public,
      anonymous: true,
    );
    expect(shown.anonymous, isFalse);
  });

  test(
    'supprimer se restaure ; seul un directeur efface pour de bon',
    () async {
      me = animator;
      final q = await questions.ask(stay, title: 'En double');
      await questions.delete(stay, q.id);
      expect(await questions.questions(stay), isEmpty);

      me = deputy;
      expect(await questions.deleted(stay), hasLength(1));
      await questions.restore(stay, q.id);
      expect(
        questions.purge(stay, q.id),
        failsWith(QuestionsErrorCode.forbidden),
      );
      me = director;
      await questions.purge(stay, q.id);
      expect(
        questions.question(stay, q.id),
        failsWith(QuestionsErrorCode.questionNotFound),
      );
    },
  );

  test('les catégories : la direction les crée, un nom par séjour', () async {
    await questions.createCategory(stay, 'Sécurité');
    expect(
      questions.createCategory(stay, ' sécurité '),
      failsWith(QuestionsErrorCode.categoryAlreadyExists),
    );
    me = animator;
    expect(
      questions.createCategory(stay, 'Repas'),
      failsWith(QuestionsErrorCode.forbidden),
    );
  });
}
