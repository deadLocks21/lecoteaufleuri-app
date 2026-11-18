import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/ui/widgets/stay_display.dart';

void main() {
  test('écrit un jour à la française', () {
    expect(displayDay(DateTime.utc(2027, 7, 10)), '10 juillet 2027');
    expect(displayDay(DateTime.utc(2027, 8, 1)), '1er août 2027');
  });

  test('ne répète ni le mois ni l\'année communs', () {
    expect(
      displayStayDates(DateTime.utc(2027, 7, 10), DateTime.utc(2027, 7, 10)),
      'Le 10 juillet 2027',
    );
    expect(
      displayStayDates(DateTime.utc(2027, 7, 10), DateTime.utc(2027, 7, 24)),
      'Du 10 au 24 juillet 2027',
    );
    expect(
      displayStayDates(DateTime.utc(2027, 6, 28), DateTime.utc(2027, 7, 5)),
      'Du 28 juin au 5 juillet 2027',
    );
    expect(
      displayStayDates(DateTime.utc(2026, 12, 30), DateTime.utc(2027, 1, 3)),
      'Du 30 décembre 2026 au 3 janvier 2027',
    );
  });

  test('un jour local et le même jour UTC s\'écrivent pareil', () {
    expect(
      displayStayDates(DateTime(2027, 7, 10), DateTime.utc(2027, 7, 10)),
      'Le 10 juillet 2027',
    );
  });
}
