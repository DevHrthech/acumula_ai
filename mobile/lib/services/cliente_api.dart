import 'dart:convert';
import 'package:http/http.dart' as http;

class ClienteApiException implements Exception {
  final String mensagem;
  final int? status;

  /// Código de negócio devolvido pela API (ex.: `CPF_EXISTENTE`), quando houver.
  final String? codigo;
  ClienteApiException(this.mensagem, {this.status, this.codigo});
  @override
  String toString() => mensagem;
}

/// Cliente HTTP do app do consumidor final. Fala direto com a API em
/// produção — não há ambiente de staging separado ainda.
class ClienteApi {
  static const String baseUrl = 'https://api.acumulaai.com.br';

  final String? token;

  ClienteApi({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _handle(http.Response res) async {
    final corpo = res.body.isEmpty ? {} : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return corpo;
    final erro = (corpo is Map && corpo['erro'] != null)
        ? corpo['erro'] as String
        : 'Erro inesperado (${res.statusCode}).';
    throw ClienteApiException(
      erro,
      status: res.statusCode,
      codigo: corpo is Map ? corpo['codigo'] as String? : null,
    );
  }

  Future<Map<String, dynamic>> cadastro({
    required String nome,
    required String cpf,
    required String senha,
    required String telefone,
    String? email,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/cadastro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'cpf': cpf,
        'senha': senha,
        'telefone': telefone,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String cpf, String senha) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cpf': cpf, 'senha': senha}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// Pede o código de recuperação por e-mail. Devolve a mensagem padrão da API
  /// (igual exista ou não a conta, por segurança).
  Future<String> esqueciSenha(String cpf) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/esqueci-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cpf': cpf}),
    );
    final corpo = await _handle(res) as Map<String, dynamic>;
    return corpo['mensagem'] as String? ?? 'Código enviado.';
  }

  Future<void> redefinirSenha({required String cpf, required String codigo, required String novaSenha}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/redefinir-senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'cpf': cpf, 'codigo': codigo, 'novaSenha': novaSenha}),
    );
    await _handle(res);
  }

  Future<List<dynamic>> atividades() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me/atividades'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> atualizarEmail(String email) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/clientes/me'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// Devolve `{cliente, token}` (conta existente) ou `{precisaCadastro: true,
  /// nome, email, tokenCadastro}` (primeiro acesso com Google).
  Future<Map<String, dynamic>> loginGoogle(String idToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completarGoogle({
    required String tokenCadastro,
    required String cpf,
    required String telefone,
    String? senha,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cliente/google/completar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tokenCadastro': tokenCadastro,
        'cpf': cpf,
        'telefone': telefone,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> meusVinculos() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me/vinculos'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> vincularLoja(String codigoLoja) async {
    final res = await http.post(
      Uri.parse('$baseUrl/clientes/me/vinculos'),
      headers: _headers,
      body: jsonEncode({'codigoLoja': codigoLoja}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// Cartões de campanha: um por campanha ativa das lojas vinculadas.
  Future<List<dynamic>> campanhas() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me/campanhas'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  /// Promoções = avisos/posts das lojas vinculadas (sem cartão fidelidade).
  Future<List<dynamic>> promocoes() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me/promocoes'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> resumo() async {
    final res = await http.get(Uri.parse('$baseUrl/clientes/me/resumo'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> solicitarMarcacao({required String empresaId, String? cupomFiscal}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/clientes/me/solicitacoes'),
      headers: _headers,
      body: jsonEncode({
        'empresaId': empresaId,
        if (cupomFiscal != null && cupomFiscal.isNotEmpty) 'cupomFiscal': cupomFiscal,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// Confirma com a [senha] ou, para quem entrou pelo Google, com um [idToken]
  /// recém-obtido da mesma conta Google.
  Future<void> excluirConta({String? senha, String? idToken}) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/clientes/me'),
      headers: _headers,
      body: jsonEncode({'senha': ?senha, 'idToken': ?idToken}),
    );
    await _handle(res);
  }

  Future<Map<String, dynamic>> atualizarPreferencias({
    bool? notificacoesPush,
    bool? notificacoesEmail,
    bool? loginBiometrico,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/clientes/me/preferencias'),
      headers: _headers,
      body: jsonEncode({
        'notificacoesPush': ?notificacoesPush,
        'notificacoesEmail': ?notificacoesEmail,
        'loginBiometrico': ?loginBiometrico,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }
}
