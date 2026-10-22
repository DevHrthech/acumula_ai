import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void baixarArquivo(Uint8List bytes, String nome, String mime) {
  final link = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = 'data:$mime;base64,${base64Encode(bytes)}'
    ..download = nome;
  link.click();
}
