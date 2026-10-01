import 'package:flutter/material.dart';
import '../services/empresa_api.dart';

/// Sessão de autenticação da Empresa logada — token JWT + dados retornados
/// pela API. Vive em memória (some com o refresh da página, igual ao
/// AdminSession do painel interno).
class EmpresaSession extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? empresa;

  bool get autenticado => token != null;

  EmpresaApi get api => EmpresaApi(token: token);

  Future<void> login(String email, String senha) async {
    final resultado = await EmpresaApi().login(email, senha);
    token = resultado['token'] as String;
    empresa = resultado['empresa'] as Map<String, dynamic>;
    notifyListeners();
  }

  void atualizarEmpresa(Map<String, dynamic> dados) {
    empresa = dados;
    notifyListeners();
  }

  void logout() {
    token = null;
    empresa = null;
    notifyListeners();
  }
}

class EmpresaSessionScope extends StatefulWidget {
  final Widget child;

  const EmpresaSessionScope({super.key, required this.child});

  @override
  State<EmpresaSessionScope> createState() => EmpresaSessionScopeState();

  static EmpresaSession of(BuildContext context) {
    final EmpresaSessionScopeState? state =
        context.findAncestorStateOfType<EmpresaSessionScopeState>();
    assert(state != null, 'No EmpresaSessionScope found in context');
    return state!.session;
  }
}

class EmpresaSessionScopeState extends State<EmpresaSessionScope> {
  late final EmpresaSession session;

  @override
  void initState() {
    super.initState();
    session = EmpresaSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, child) => _InheritedEmpresaSessionScope(
        session: session,
        child: widget.child,
      ),
    );
  }
}

class _InheritedEmpresaSessionScope extends InheritedWidget {
  final EmpresaSession session;

  const _InheritedEmpresaSessionScope({
    required this.session,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedEmpresaSessionScope oldWidget) {
    return session != oldWidget.session;
  }
}
