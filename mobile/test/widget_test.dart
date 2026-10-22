import 'package:flutter_test/flutter_test.dart';

import 'package:acumulaai_mobile/main.dart';

void main() {
  testWidgets('App inicia na tela de login quando não há sessão guardada', (WidgetTester tester) async {
    await tester.pumpWidget(const AcumulaAiApp());
    // Primeiro o app tenta retomar a sessão guardada no aparelho (mostra um
    // indicador de carregamento que nunca "assenta", então não dá pra usar
    // pumpAndSettle). Sem o plugin de armazenamento seguro no teste, a leitura
    // falha na hora e o app cai na tela de login.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Entrar'), findsOneWidget);
  });
}
