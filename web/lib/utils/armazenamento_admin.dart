import 'package:web/web.dart' as web;

/// Guarda o token do painel admin. Por padrão só na ABA aberta (sessionStorage):
/// sobrevive a atualizar a página, mas some ao fechar a aba/navegador — o
/// admin enxerga todas as empresas, então não fica gravado de forma
/// permanente por padrão. A tela de login oferece "Lembrar acesso neste
/// dispositivo" como opt-in explícito: só então vai para localStorage
/// (persiste entre sessões do navegador; o servidor emite um token de 14 dias).
/// Só o token é guardado — nunca e-mail nem senha. Qualquer falha (modo
/// privado, storage bloqueado) é ignorada: o painel só volta a pedir login.
class ArmazenamentoAdmin {
  static const _chave = 'acumulaai_admin_token';

  static String? ler() {
    try {
      return web.window.sessionStorage.getItem(_chave) ?? web.window.localStorage.getItem(_chave);
    } catch (_) {
      return null;
    }
  }

  static void salvar(String token, {bool lembrar = false}) {
    try {
      // Sem isto, um token "lembrado" de um login anterior sobrevive a um login
      // novo sem "Lembrar acesso" e reabre o painel depois de fechar o navegador.
      web.window.sessionStorage.removeItem(_chave);
      web.window.localStorage.removeItem(_chave);
      if (lembrar) {
        web.window.localStorage.setItem(_chave, token);
      } else {
        web.window.sessionStorage.setItem(_chave, token);
      }
    } catch (_) {}
  }

  static void limpar() {
    try {
      web.window.sessionStorage.removeItem(_chave);
      web.window.localStorage.removeItem(_chave);
    } catch (_) {}
  }
}
