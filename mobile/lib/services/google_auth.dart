import 'package:google_sign_in/google_sign_in.dart';
import '../config/google.dart';

/// Acesso único ao "Entrar com Google": usado no login e também para
/// confirmar a exclusão de conta de quem entrou pelo Google (essas contas não
/// têm senha que o cliente conheça).
class GoogleAuth {
  static bool _inicializado = false;

  static bool get disponivel => googleWebClientId.isNotEmpty;

  static Future<void> _garantirInicializado() async {
    if (_inicializado) return;
    await GoogleSignIn.instance.initialize(serverClientId: googleWebClientId);
    _inicializado = true;
  }

  /// Abre o seletor de contas e devolve o ID token (ou null se o Google não
  /// entregou um). Cancelar o seletor lança [GoogleSignInException] com
  /// `code == canceled`.
  static Future<String?> obterIdToken() async {
    await _garantirInicializado();
    final conta = await GoogleSignIn.instance.authenticate();
    return conta.authentication.idToken;
  }

  /// Sai da conta Google do aparelho para o próximo "Entrar com Google"
  /// mostrar o seletor de contas de novo. Nunca falha para quem chama.
  static Future<void> sair() async {
    try {
      await _garantirInicializado();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
