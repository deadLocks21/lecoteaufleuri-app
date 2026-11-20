import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/core/domain/model/news.dart';
import 'package:lecoteaufleuri/ui/pages/news/news_display.dart';

void main() {
  test('titre un jour à la française', () {
    expect(displayNewsDay(DateTime.utc(2027, 7, 12)), 'Lundi 12 juillet');
    expect(displayNewsDay(DateTime.utc(2027, 8, 1)), 'Dimanche 1er août');
    expect(displayShortDay(DateTime.utc(2027, 7, 12)), '12 juil.');
  });

  test('dit ce que la publication veut dire pour les familles', () {
    expect(
      dayStatusDescription(DayStatus.draft, null),
      'Invisible des familles tant qu\'il n\'est pas publié.',
    );
    expect(
      dayStatusDescription(DayStatus.scheduled, DateTime(2027, 7, 12, 20)),
      'Paraîtra le lundi 12 juillet 2027 à 20:00.',
    );
  });

  test('compte les photos', () {
    expect(photoCount(0), 'aucune photo');
    expect(photoCount(1), '1 photo');
    expect(photoCount(3), '3 photos');
  });
}
