import 'package:web/web.dart' as web;

/// Abre um link externo (ex: fatura do Asaas) em uma nova aba. Só aceita https.
void abrirLink(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return;
  web.window.open(url, '_blank');
}
