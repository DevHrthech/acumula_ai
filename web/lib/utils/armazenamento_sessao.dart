import 'package:web/web.dart' as web;

/// Guarda o token da sessão da Empresa no navegador, pra sobreviver a
/// refresh/fechar a aba. Qualquer falha (modo privado, storage bloqueado) é
/// ignorada — o app só volta a pedir login.
class ArmazenamentoSessao {
  static const _chave = 'acumulaai_empresa_token';

  static String? ler() {
    try {
      return web.window.localStorage.getItem(_chave);
    } catch (_) {
      return null;
    }
  }

  static void salvar(String token) {
    try {
      web.window.localStorage.setItem(_chave, token);
    } catch (_) {}
  }

  static void limpar() {
    try {
      web.window.localStorage.removeItem(_chave);
    } catch (_) {}
  }
}
