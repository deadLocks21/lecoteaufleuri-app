import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

void main() {
  group('Session', () {
    final session = sessionExpiringAt(DateTime.utc(2026, 1, 31, 12));

    test('reste valable jusqu\'à une minute de son échéance', () {
      expect(session.isExpiredAt(DateTime.utc(2026, 1, 31, 11, 58)), isFalse);
      expect(session.isExpiredAt(DateTime.utc(2026, 1, 31, 11, 59)), isTrue);
      expect(session.isExpiredAt(DateTime.utc(2026, 2, 1)), isTrue);
    });
  });
}
