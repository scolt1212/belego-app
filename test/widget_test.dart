import 'package:flutter_test/flutter_test.dart';

import 'package:belego/main.dart';

void main() {
  testWidgets('Zeigt die 4 Tabs und den Heute-Screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BelegoApp());

    expect(find.text('Heute'), findsWidgets);
    expect(find.text('Assistent'), findsOneWidget);
    expect(find.text('Dokumente'), findsOneWidget);
    expect(find.text('Kontakte'), findsOneWidget);
    expect(find.text('Offene Forderungen'), findsOneWidget);
  });
}
