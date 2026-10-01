import 'package:flutter/foundation.dart';
import '../services/admin_api.dart';

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
    notifyListeners();
  }

  void logout() {
    token = null;
    nome = null;
    email = null;
    notifyListeners();
  }
}
