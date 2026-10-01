import 'dart:convert';
import 'package:http/http.dart' as http;

class ClienteApiException implements Exception {
  final String mensagem;
  ClienteApiException(this.mensagem);
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
    throw ClienteApiException(erro);
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

  Future<Map<String, dynamic>> atualizarPreferencias({
    bool? notificacoesPush,
    bool? notificacoesEmail,
    bool? loginBiometrico,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/clientes/me/preferencias'),
      headers: _headers,
      body: jsonEncode({
        if (notificacoesPush != null) 'notificacoesPush': notificacoesPush,
        if (notificacoesEmail != null) 'notificacoesEmail': notificacoesEmail,
        if (loginBiometrico != null) 'loginBiometrico': loginBiometrico,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }
}
