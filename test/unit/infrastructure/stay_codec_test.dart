import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/stay.dart';
import 'package:lecoteaufleuri/core/domain/model/stay_draft.dart';
import 'package:lecoteaufleuri/infrastructure/stays/stay.codec.dart';

void main() {
  const json = {
    'id': '5d1e0000-0000-4000-8000-000000000001',
    'name': 'Été 2027',
    'kind': 'acm',
    'starts_on': '2027-07-10',
    'ends_on': '2027-07-24',
  };

  test('lit un séjour de l\'API', () {
    expect(
      StayCodec.fromJson(json),
      Stay(
        id: '5d1e0000-0000-4000-8000-000000000001',
        name: 'Été 2027',
        kind: StayKind.acm,
        startsOn: DateTime.utc(2027, 7, 10),
        endsOn: DateTime.utc(2027, 7, 24),
      ),
    );
    expect(StayCodec.fromJson({...json, 'kind': 'other'}).kind, StayKind.other);
  });

  test('refuse un séjour qui n\'a pas la forme attendue', () {
    for (final malformed in <Object?>[
      null,
      'Été 2027',
      {...json}..remove('name'),
      {...json, 'id': ''},
      {...json, 'kind': 'colo'},
      {...json, 'starts_on': '10/07/2027'},
      {...json, 'ends_on': '2027-02-31'},
      {...json, 'starts_on': '2027-07-24', 'ends_on': '2027-07-10'},
    ]) {
      expect(
        () => StayCodec.fromJson(malformed),
        throwsFormatException,
        reason: '$malformed',
      );
    }
  });

  test('écrit une saisie comme l\'API l\'attend', () {
    final draft = StayDraft.parse(
      name: 'Week-end',
      kind: StayKind.other,
      startsOn: DateTime(2027, 3, 6),
      endsOn: DateTime(2027, 3, 7),
    );

    expect(StayCodec.toJson(draft), {
      'name': 'Week-end',
      'kind': 'other',
      'starts_on': '2027-03-06',
      'ends_on': '2027-03-07',
    });
  });
}
