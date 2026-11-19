import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/phone_number.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';

/// Les règles de l'API, rejouées en mémoire (cf. `API.md` du dépôt api).
void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';
  const weekend = '5d1e0000-0000-4000-8000-000000000002';
  const dominique = '0a5c0000-0000-4000-8000-000000000101';
  const sacha = '0a5c0000-0000-4000-8000-000000000102';
  final sachaPhone = PhoneNumber.parse('06 33 33 33 33');
  final dominiquePhone = PhoneNumber.parse('06 22 22 22 22');

  Matcher failsWith(StayErrorCode expected) =>
      throwsA(isA<StayException>().having((e) => e.code, 'code', expected));

  InMemoryStayRepository as(String id, {bool admin = false}) =>
      InMemoryStayRepository(viewer: () => (id: id, isAdmin: admin));

  test(
    'un adjoint nommé directeur rejoint les directeurs et quitte les adjoints',
    () async {
      final repository = as('admin', admin: true);
      await repository.addDeputy(summer, sachaPhone);

      final detail = await repository.nameDirector(summer, sachaPhone);

      expect(
        detail.directors.map((d) => d.id),
        containsAll([dominique, sacha]),
      );
      expect(detail.deputies, isEmpty);
    },
  );

  test('le directeur nomme ses adjoints, pas le directeur', () async {
    final repository = as(dominique);

    final detail = await repository.addDeputy(summer, sachaPhone);
    expect(detail.deputies.single.id, sacha);
    expect(detail.canManageDirectors, isFalse);
    expect(detail.canManageDeputies, isTrue);

    await expectLater(
      repository.nameDirector(summer, sachaPhone),
      failsWith(StayErrorCode.forbidden),
    );
  });

  test('un adjoint voit le séjour sans pouvoir nommer personne', () async {
    final repository = InMemoryStayRepository(
      staff: {
        summer: {dominique: StaffRole.director, sacha: StaffRole.deputy},
      },
      viewer: () => (id: sacha, isAdmin: false),
    );

    final detail = await repository.get(summer);
    expect(detail.canManageDeputies, isFalse);
    expect((await repository.mine()).single.role, StaffRole.deputy);
    await expectLater(
      repository.removeDeputy(summer, sacha),
      failsWith(StayErrorCode.forbidden),
    );
  });

  test('sans lien, le séjour n\'existe pas', () async {
    await expectLater(as(sacha).get(summer), failsWith(StayErrorCode.notFound));
  });

  test('hors ACM, ni directeur ni adjoint', () async {
    final repository = as('admin', admin: true);

    await expectLater(
      repository.nameDirector(weekend, sachaPhone),
      failsWith(StayErrorCode.notAcm),
    );
    expect((await repository.get(weekend)).canManageDirectors, isFalse);
  });

  test('le directeur ne peut pas être adjoint, et le numéro doit avoir un '
      'compte', () async {
    final repository = as('admin', admin: true);

    await expectLater(
      repository.addDeputy(summer, dominiquePhone),
      failsWith(StayErrorCode.alreadyDirector),
    );
    await expectLater(
      repository.addDeputy(summer, PhoneNumber.parse('06 99 99 99 99')),
      failsWith(StayErrorCode.unknownPhone),
    );
  });

  test('un numéro sans compte en reçoit un si l\'on donne les noms', () async {
    final repository = as(dominique);
    final lou = PhoneNumber.parse('07 11 22 33 44');

    await expectLater(
      repository.addDeputy(summer, lou),
      failsWith(StayErrorCode.unknownPhone),
    );
    final detail = await repository.addDeputy(
      summer,
      lou,
      newAccount: NewStaffAccount.parse(firstName: 'Lou', lastName: 'Petit'),
    );

    expect(detail.deputies.single.lastName, 'Petit');
  });

  test('hors ACM, aucun compte n\'est créé', () async {
    final repository = as('admin', admin: true);
    final lou = PhoneNumber.parse('07 11 22 33 44');

    await expectLater(
      repository.nameDirector(
        weekend,
        lou,
        newAccount: NewStaffAccount.parse(firstName: 'Lou', lastName: 'Petit'),
      ),
      failsWith(StayErrorCode.notAcm),
    );
    // Toujours inconnu : la création n'a pas eu lieu.
    await expectLater(
      repository.addDeputy(summer, lou),
      failsWith(StayErrorCode.unknownPhone),
    );
  });
}
