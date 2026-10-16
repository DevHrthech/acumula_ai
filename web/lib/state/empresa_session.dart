import 'package:flutter/material.dart';
import '../services/empresa_api.dart';
import '../utils/armazenamento_sessao.dart';

/// Sessão de autenticação da Empresa logada — token JWT + dados retornados
/// pela API. O token também fica no localStorage do navegador, então a
/// sessão sobrevive a refresh e a fechar/reabrir a aba, até o JWT expirar
/// (7 dias).
class EmpresaSession extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? empresa;

  bool get autenticado => token != null;

  EmpresaApi get api => EmpresaApi(token: token);

  Future<void> login(String email, String senha) async {
    final resultado = await EmpresaApi().login(email, senha);
    token = resultado['token'] as String;
    empresa = resultado['empresa'] as Map<String, dynamic>;
    ArmazenamentoSessao.salvar(token!);
    notifyListeners();
  }

  /// Tenta retomar a sessão guardada no navegador. Devolve true se havia
  /// token e a API ainda o aceita. Token rejeitado (expirado/licença
  /// bloqueada) é descartado; falha de rede mantém o token guardado, mas não
  /// autentica agora.
  Future<bool> restaurar() async {
    final guardado = ArmazenamentoSessao.ler();
    if (guardado == null || guardado.isEmpty) return false;
    try {
      final dados = await EmpresaApi(token: guardado).me();
      token = guardado;
      empresa = dados;
      notifyListeners();
      return true;
    } on EmpresaApiException catch (e) {
      // Só descarta o token quando a API o recusou (401 expirado/inválido ou
      // 403 licença bloqueada). Erro 5xx ou limite de requisições (429) é
      // instabilidade passageira: manter o token evita deslogar a loja à toa.
      if (e.status == 401 || e.status == 403) ArmazenamentoSessao.limpar();
      return false;
    } catch (_) {
      return false;
    }
  }

  void atualizarEmpresa(Map<String, dynamic> dados) {
    empresa = dados;
    notifyListeners();
  }

  void logout() {
    ArmazenamentoSessao.limpar();
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
