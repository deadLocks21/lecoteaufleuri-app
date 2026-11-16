import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lecoteaufleuri/main.dart';

void main() {
  testWidgets('affiche Hello, World!', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('Hello, World!'), findsOneWidget);
  });
}
