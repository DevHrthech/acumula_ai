import 'package:web/web.dart' as web;

/// Guarda o token do painel admin só na ABA aberta (sessionStorage): sobrevive
/// a atualizar a página, mas some ao fechar a aba/navegador — o admin enxerga
/// todas as empresas, então não fica gravado de forma permanente como o da
/// Empresa. Qualquer falha (modo privado, storage bloqueado) é ignorada: o
/// painel só volta a pedir login.
class ArmazenamentoAdmin {
  static const _chave = 'acumulaai_admin_token';

  static String? ler() {
    try {
      return web.window.sessionStorage.getItem(_chave);
    } catch (_) {
      return null;
    }
  }

  static void salvar(String token) {
    try {
      web.window.sessionStorage.setItem(_chave, token);
    } catch (_) {}
  }

  static void limpar() {
    try {
      web.window.sessionStorage.removeItem(_chave);
    } catch (_) {}
  }
}
