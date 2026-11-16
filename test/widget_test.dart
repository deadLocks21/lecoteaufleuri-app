import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/main.dart';

void main() {
  testWidgets('affiche Hello, World!', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
