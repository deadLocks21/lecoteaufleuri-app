import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/main.dart';

void main() {
  testWidgets("l'accueil affiche Hello, World!", (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LeCoteauFleuriApp()));

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
