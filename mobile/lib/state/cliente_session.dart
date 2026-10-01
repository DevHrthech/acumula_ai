import 'package:flutter/material.dart';
import '../services/cliente_api.dart';

/// Sessão de autenticação do Cliente logado — token JWT + dados retornados
/// pela API. Vive em memória (some com o restart do app, sem "lembrar de
/// mim" por enquanto).
class ClienteSession extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? cliente;
  List<dynamic> vinculos = [];
  Map<String, dynamic>? resumo;

  bool get autenticado => token != null;

  ClienteApi get api => ClienteApi(token: token);

  Future<void> cadastro({
    required String nome,
    required String cpf,
    required String senha,
    required String telefone,
    String? email,
  }) async {
    final resultado = await ClienteApi().cadastro(
      nome: nome,
      cpf: cpf,
      senha: senha,
      telefone: telefone,
      email: email,
    );
    token = resultado['token'] as String;
    cliente = resultado['cliente'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> login(String cpf, String senha) async {
    final resultado = await ClienteApi().login(cpf, senha);
    token = resultado['token'] as String;
    cliente = resultado['cliente'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> carregarVinculos() async {
    vinculos = await api.meusVinculos();
    notifyListeners();
  }

  Future<Map<String, dynamic>> vincularLoja(String codigoLoja) async {
    final vinculo = await api.vincularLoja(codigoLoja);
    vinculos = [vinculo, ...vinculos];
    notifyListeners();
    return vinculo;
  }

  Future<void> carregarResumo() async {
    resumo = await api.resumo();
    notifyListeners();
  }

  Future<void> solicitarMarcacao({required String empresaId, String? cupomFiscal}) async {
    await api.solicitarMarcacao(empresaId: empresaId, cupomFiscal: cupomFiscal);
  }

  Future<void> atualizarPreferencias({bool? notificacoesPush, bool? notificacoesEmail, bool? loginBiometrico}) async {
    cliente = await api.atualizarPreferencias(
      notificacoesPush: notificacoesPush,
      notificacoesEmail: notificacoesEmail,
      loginBiometrico: loginBiometrico,
    );
    notifyListeners();
  }

  void logout() {
    token = null;
    cliente = null;
    vinculos = [];
    notifyListeners();
  }
}

class ClienteSessionScope extends StatefulWidget {
  final Widget child;

  const ClienteSessionScope({super.key, required this.child});

  @override
  State<ClienteSessionScope> createState() => ClienteSessionScopeState();

  static ClienteSession of(BuildContext context) {
    final ClienteSessionScopeState? state =
        context.findAncestorStateOfType<ClienteSessionScopeState>();
    assert(state != null, 'No ClienteSessionScope found in context');
    return state!.session;
  }
}

class ClienteSessionScopeState extends State<ClienteSessionScope> {
  late final ClienteSession session;

  @override
  void initState() {
    super.initState();
    session = ClienteSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, child) => _InheritedClienteSessionScope(
        session: session,
        child: widget.child,
      ),
    );
  }
}

class _InheritedClienteSessionScope extends InheritedWidget {
  final ClienteSession session;

  const _InheritedClienteSessionScope({
    required this.session,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedClienteSessionScope oldWidget) {
    return session != oldWidget.session;
  }
}
