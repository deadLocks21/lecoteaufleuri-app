import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/exceptions/stay.exception.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';

void main() {
  Matcher failsWith(StayErrorCode expected) =>
      throwsA(isA<StayException>().having((e) => e.code, 'code', expected));

  StayDraft parse({
    String name = 'Été 2027',
    StayKind? kind = StayKind.acm,
    DateTime? startsOn,
    DateTime? endsOn,
  }) => StayDraft.parse(
    name: name,
    kind: kind,
    startsOn: startsOn ?? DateTime(2027, 7, 10),
    endsOn: endsOn ?? DateTime(2027, 7, 24),
  );

  test('ramène les dates à leur jour, à minuit UTC, et le nom sans '
      'espaces de bord', () {
    final draft = parse(
      name: '  Été 2027  ',
      startsOn: DateTime(2027, 7, 10, 18, 30),
      endsOn: DateTime(2027, 7, 24, 23, 59),
    );

    expect(draft.name, 'Été 2027');
    expect(draft.startsOn, DateTime.utc(2027, 7, 10));
    expect(draft.endsOn, DateTime.utc(2027, 7, 24));
  });

  test('un séjour peut tenir en un jour', () {
    final draft = parse(
      startsOn: DateTime(2027, 7, 10, 8),
      endsOn: DateTime(2027, 7, 10, 7),
    );

    expect(draft.endsOn, draft.startsOn);
  });

  test('le nom est obligatoire et tient en 255 caractères', () {
    expect(() => parse(name: '   '), failsWith(StayErrorCode.invalidName));
    expect(() => parse(name: 'a' * 256), failsWith(StayErrorCode.invalidName));
    // Compté en caractères comme l'API, pas en unités UTF-16.
    expect(parse(name: '🏕' * 255).name.runes.length, 255);
  });

  test('la nature doit être choisie', () {
    expect(() => parse(kind: null), failsWith(StayErrorCode.invalidKind));
  });

  test('les deux dates sont obligatoires, la fin au plus tôt le jour du '
      'début', () {
    expect(
      () => StayDraft.parse(
        name: 'Été 2027',
        kind: StayKind.acm,
        startsOn: null,
        endsOn: DateTime(2027, 7, 24),
      ),
      failsWith(StayErrorCode.invalidDates),
    );
    expect(
      () =>
          parse(startsOn: DateTime(2027, 7, 24), endsOn: DateTime(2027, 7, 10)),
      failsWith(StayErrorCode.invalidDates),
    );
  });

  test('signale les erreurs dans l\'ordre du formulaire', () {
    expect(
      () => StayDraft.parse(name: '', kind: null, startsOn: null, endsOn: null),
      failsWith(StayErrorCode.invalidName),
    );
  });
}
