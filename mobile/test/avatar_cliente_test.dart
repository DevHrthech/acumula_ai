import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:acumulaai_mobile/widgets/avatar_cliente.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// Confere por pixels que a foto preenche TODO o círculo do avatar (sem trechos
// retos nas quatro laterais) e que o anel branco aparece inteiro. Regressão do
// avatar que parecia um quadrado de cantos arredondados.
void main() {
  testWidgets('avatar: foto ocupa o círculo inteiro e o anel aparece inteiro', (tester) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Foto sintética toda VERMELHA (fácil de distinguir do anel branco e do fundo roxo).
    final im = img.Image(width: 400, height: 400);
    img.fill(im, color: img.ColorRgb8(255, 0, 0));
    final bytes = Uint8List.fromList(img.encodePng(im));
    final servidor = (await tester.runAsync(() => HttpServer.bind(InternetAddress.loopbackIPv4, 0)))!;
    servidor.listen((req) {
      req.response.headers.contentType = ContentType('image', 'png');
      req.response.add(bytes);
      req.response.close();
    });
    HttpOverrides.global = null; // o flutter_test bloqueia rede por padrão

    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: const Color(0xFF5B0A8F), // roxo
            alignment: Alignment.center,
            child: AvatarCliente(
              fotoUrl: 'http://localhost:${servidor.port}/f.png',
              nome: 'Lucas',
              tamanho: 300,
              fundo: Colors.white,
              corTexto: Colors.black,
              borda: Colors.white,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
    }

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final imagem = (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
    final dados = (await tester.runAsync(() => imagem.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
    List<int> px(int x, int y) {
      final i = (y * imagem.width + x) * 4;
      return [dados.getUint8(i), dados.getUint8(i + 1), dados.getUint8(i + 2)];
    }

    bool vermelho(List<int> c) => c[0] > 200 && c[1] < 60 && c[2] < 60;
    bool branco(List<int> c) => c[0] > 230 && c[1] > 230 && c[2] > 230;
    bool roxo(List<int> c) => c[0] < 120 && c[2] > 100 && c[1] < 60;

    // Círculo de 300 px centrado em 600x600: ocupa de 150 a 450. O anel branco
    // tem 3 px: de 150 a 153 nas bordas. Logo depois do anel já tem que ser foto.
    expect(branco(px(300, 151)), isTrue, reason: 'topo do anel');
    expect(vermelho(px(300, 156)), isTrue, reason: 'logo abaixo do anel, no topo — antes era anel/reto');
    expect(vermelho(px(300, 444)), isTrue, reason: 'base');
    expect(vermelho(px(156, 300)), isTrue, reason: 'esquerda');
    expect(vermelho(px(444, 300)), isTrue, reason: 'direita');
    expect(vermelho(px(300, 300)), isTrue, reason: 'centro');
    // O anel branco (3 px) tem que aparecer INTEIRO, inclusive nas diagonais — era ali
    // que a foto antiga o cobria e o avatar parecia um quadrado de cantos arredondados.
    for (final c in [[1, 1], [1, -1], [-1, 1], [-1, -1]]) {
      final x = (300 + 148.5 * 0.70710678 * c[0]).round();
      final y = (300 + 148.5 * 0.70710678 * c[1]).round();
      expect(branco(px(x, y)), isTrue, reason: 'anel branco na diagonal ($x,$y)');
    }
    // Cantos do quadrado envolvente: fora do círculo => roxo (foto não vaza).
    expect(roxo(px(155, 155)), isTrue, reason: 'canto superior esquerdo fora do círculo');
    expect(roxo(px(445, 445)), isTrue, reason: 'canto inferior direito fora do círculo');
    // ignore: avoid_print
    print('PIXELS_OK: foto preenche o circulo inteiro e nao vaza nos cantos');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30)); // dispara o timer ocioso do cliente HTTP
    await tester.runAsync(() => servidor.close(force: true));
  });
}
