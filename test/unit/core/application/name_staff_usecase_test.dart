import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/application/usecases/stay_team.usecases.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_team.dart';
import 'package:lecoteaufleuri/infrastructure/stays/in_memory.stay.repository.dart';

void main() {
  const summer = '5d1e0000-0000-4000-8000-000000000001';

  test('normalise la saisie libre avant de nommer', () async {
    final detail = await NameStaffUseCase(
      InMemoryStayRepository(),
    ).execute(summer, StaffRole.deputy, rawPhone: '+33 6 33 33 33 33');

    expect(detail.deputies.single.lastName, 'Bernard');
  });

  test('refuse un numéro qui n\'est pas un mobile, sans appeler l\'API', () {
    expect(
      () => NameStaffUseCase(
        InMemoryStayRepository(),
      ).execute(summer, StaffRole.director, rawPhone: '01 23 45 67 89'),
      throwsA(
        isA<StayException>().having(
          (e) => e.code,
          'code',
          StayErrorCode.invalidPhone,
        ),
      ),
    );
  });

  test('crée le compte d\'un numéro inconnu avec des noms non vides', () async {
    final useCase = NameStaffUseCase(InMemoryStayRepository());

    final detail = await useCase.execute(
      summer,
      StaffRole.deputy,
      rawPhone: '07 11 22 33 44',
      firstName: ' Lou ',
      lastName: 'Petit',
    );
    expect(detail.deputies.single.firstName, 'Lou');

    expect(
      () => useCase.execute(
        summer,
        StaffRole.deputy,
        rawPhone: '07 55 66 77 88',
        firstName: 'Lou',
        lastName: ' ',
      ),
      throwsA(
        isA<StayException>().having(
          (e) => e.code,
          'code',
          StayErrorCode.invalidPersonName,
        ),
      ),
    );
  });

  test('ajoute un animateur, et ne rétrograde que sur demande', () async {
    final useCase = NameStaffUseCase(InMemoryStayRepository());

    final added = await useCase.execute(
      summer,
      StaffRole.animator,
      rawPhone: '06 33 33 33 33',
    );
    expect(added.animators.single.lastName, 'Bernard');

    await expectLater(
      useCase.execute(summer, StaffRole.animator, rawPhone: '06 22 22 22 22'),
      throwsA(
        isA<StayException>().having(
          (e) => e.code,
          'code',
          StayErrorCode.alreadyDirector,
        ),
      ),
    );
    final demoted = await useCase.execute(
      summer,
      StaffRole.animator,
      rawPhone: '06 22 22 22 22',
      demote: true,
    );
    expect(demoted.directors, isEmpty);
    expect(demoted.animators.map((a) => a.lastName), ['Bernard', 'Durand']);
  });
}
