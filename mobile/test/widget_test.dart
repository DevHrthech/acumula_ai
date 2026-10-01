import 'package:flutter_test/flutter_test.dart';

import 'package:acumulaai_mobile/main.dart';

void main() {
  testWidgets('App inicia na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const AcumulaAiApp());
    await tester.pump();

    expect(find.text('Entrar'), findsOneWidget);
  });
}
