import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/cliente_api.dart';
import '../services/google_auth.dart';

/// Sessão de autenticação do Cliente logado — token JWT + dados retornados
/// pela API. O token fica guardado no armazenamento seguro do aparelho
/// (Android Keystore) para o cliente não precisar entrar de novo a cada vez
/// que abre o app; ele vale 30 dias no servidor. Sair da conta (ou excluí-la)
/// apaga o token guardado.
class ClienteSession extends ChangeNotifier {
  static const _chaveToken = 'cliente_token';
  static const _storage = FlutterSecureStorage();

  String? token;
  Map<String, dynamic>? cliente;
  List<dynamic> vinculos = [];
  List<dynamic> campanhas = [];
  List<dynamic> promocoes = [];
  Map<String, dynamic>? resumo;

  bool get autenticado => token != null;

  ClienteApi get api => ClienteApi(token: token);

  Future<void> _guardarToken() async {
    try {
      if (token != null) await _storage.write(key: _chaveToken, value: token);
    } catch (_) {
      // Sem armazenamento seguro disponível: a sessão continua só em memória.
    }
  }

  /// Tenta retomar a sessão guardada ao abrir o app. Devolve true se o token
  /// ainda é válido (dados do cliente carregados). Token recusado pelo servidor
  /// (expirado/conta removida) é apagado; falha de rede mantém o token guardado
  /// para a próxima abertura, mas devolve false.
  Future<bool> restaurar() async {
    String? guardado;
    try {
      guardado = await _storage.read(key: _chaveToken);
    } catch (_) {
      return false;
    }
    if (guardado == null || guardado.isEmpty) return false;

    try {
      final perfil = await ClienteApi(token: guardado).me();
      token = guardado;
      cliente = perfil;
      notifyListeners();
      return true;
    } on ClienteApiException catch (e) {
      // Só apaga quando o servidor recusou o token; erro 5xx/instabilidade
      // não deve deslogar o cliente.
      if (e.status == 401 || e.status == 403 || e.status == 404) await _apagarToken();
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _apagarToken() async {
    try {
      await _storage.delete(key: _chaveToken);
    } catch (_) {}
  }

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
    await _guardarToken();
    notifyListeners();
  }

  Future<void> login(String cpf, String senha) async {
    final resultado = await ClienteApi().login(cpf, senha);
    token = resultado['token'] as String;
    cliente = resultado['cliente'] as Map<String, dynamic>;
    await _guardarToken();
    notifyListeners();
  }

  /// Devolve null quando entrou; ou os dados do primeiro acesso (nome, e-mail,
  /// tokenCadastro) quando ainda falta CPF e telefone.
  Future<Map<String, dynamic>?> loginGoogle(String idToken) async {
    final resultado = await ClienteApi().loginGoogle(idToken);
    if (resultado['precisaCadastro'] == true) return resultado;
    token = resultado['token'] as String;
    cliente = resultado['cliente'] as Map<String, dynamic>;
    await _guardarToken();
    notifyListeners();
    return null;
  }

  Future<void> completarGoogle({
    required String tokenCadastro,
    required String cpf,
    required String telefone,
    String? senha,
  }) async {
    final resultado = await ClienteApi().completarGoogle(tokenCadastro: tokenCadastro, cpf: cpf, telefone: telefone, senha: senha);
    token = resultado['token'] as String;
    cliente = resultado['cliente'] as Map<String, dynamic>;
    await _guardarToken();
    notifyListeners();
  }

  Future<void> carregarVinculos() async {
    vinculos = await api.meusVinculos();
    notifyListeners();
  }

  Future<void> carregarCampanhas() async {
    campanhas = await api.campanhas();
    notifyListeners();
  }

  Future<void> carregarPromocoes() async {
    promocoes = await api.promocoes();
    notifyListeners();
  }

  Future<Map<String, dynamic>> vincularLoja(String codigoLoja) async {
    final vinculo = await api.vincularLoja(codigoLoja);
    vinculos = [vinculo, ...vinculos];
    notifyListeners();
    // A loja nova traz as campanhas e promoções dela — recarrega sem travar
    // o vínculo se a rede falhar agora.
    try {
      await Future.wait([carregarCampanhas(), carregarPromocoes()]);
    } catch (_) {}
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

  Future<void> atualizarEmail(String email) async {
    cliente = await api.atualizarEmail(email);
    notifyListeners();
  }

  Future<void> excluirConta({String? senha, String? idToken}) async {
    await api.excluirConta(senha: senha, idToken: idToken);
    logout();
  }

  void logout() {
    _apagarToken();
    // Sai também da conta Google do aparelho (senão o próximo "Entrar com
    // Google" pode reaproveitar a conta anterior sem mostrar o seletor).
    GoogleAuth.sair();
    token = null;
    cliente = null;
    vinculos = [];
    campanhas = [];
    promocoes = [];
    resumo = null;
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
