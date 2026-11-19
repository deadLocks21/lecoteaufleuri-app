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
}
