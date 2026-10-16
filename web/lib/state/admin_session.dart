import 'package:flutter/foundation.dart';
import '../services/admin_api.dart';
import '../utils/armazenamento_admin.dart';

class AdminSession extends ChangeNotifier {
  String? token;
  String? nome;
  String? email;

  bool get autenticado => token != null;

  AdminApi get api => AdminApi(token: token);

  Future<void> login(String email, String senha) async {
    final resultado = await AdminApi().login(email, senha);
    token = resultado['token'] as String;
    final admin = resultado['admin'] as Map<String, dynamic>;
    nome = admin['nome'] as String;
    this.email = admin['email'] as String;
    ArmazenamentoAdmin.salvar(token!);
    notifyListeners();
  }

  /// Retoma a sessão guardada na aba (atualizar a página não desloga). Só
  /// descarta o token quando a API o recusa (401/403); falha de rede ou 5xx
  /// mantém.
  Future<bool> restaurar() async {
    final guardado = ArmazenamentoAdmin.ler();
    if (guardado == null || guardado.isEmpty) return false;
    try {
      final admin = await AdminApi(token: guardado).me();
      token = guardado;
      nome = admin['nome'] as String;
      email = admin['email'] as String;
      notifyListeners();
      return true;
    } on AdminApiException catch (e) {
      if (e.status == 401 || e.status == 403) ArmazenamentoAdmin.limpar();
      return false;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    ArmazenamentoAdmin.limpar();
    token = null;
    nome = null;
    email = null;
    notifyListeners();
  }
}
