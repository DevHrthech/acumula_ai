import 'dart:convert';
import 'package:http/http.dart' as http;

class EmpresaApiException implements Exception {
  final String mensagem;

  /// Código HTTP da resposta (nulo se o erro não veio de uma resposta da API).
  final int? status;
  EmpresaApiException(this.mensagem, {this.status});
  @override
  String toString() => mensagem;
}

/// Cliente HTTP do painel da Empresa (loja). Fala direto com a API em
/// produção — não há ambiente de staging separado ainda.
class EmpresaApi {
  static const String baseUrl = 'https://api.acumulaai.com.br';

  /// Chamado quando uma requisição autenticada volta 401 (token expirado ou
  /// inválido) — o app registra aqui o que fazer (limpar sessão e ir pro login).
  static void Function()? aoSessaoExpirar;

  final String? token;

  EmpresaApi({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _handle(http.Response res) async {
    final corpo = res.body.isEmpty ? {} : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return corpo;
    if (res.statusCode == 401 && token != null) aoSessaoExpirar?.call();
    final erro = (corpo is Map && corpo['erro'] != null)
        ? corpo['erro'] as String
        : 'Erro inesperado (${res.statusCode}).';
    throw EmpresaApiException(erro, status: res.statusCode);
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/empresa/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/empresas/me'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarMe(Map<String, dynamic> dados) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/empresas/me'),
      headers: _headers,
      body: jsonEncode(dados),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// [tipo]: `icone`, `logo-qrcode` ou `logo-promocao`. Devolve a empresa
  /// atualizada (com a nova URL da imagem).
  Future<Map<String, dynamic>> enviarImagem(String tipo, List<int> bytes, String contentType) async {
    final res = await http.put(
      Uri.parse('$baseUrl/empresas/me/imagens/$tipo'),
      headers: {
        'Content-Type': contentType,
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: bytes,
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removerImagem(String tipo) async {
    final res = await http.delete(Uri.parse('$baseUrl/empresas/me/imagens/$tipo'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listarCampanhas() async {
    final res = await http.get(Uri.parse('$baseUrl/empresas/me/campanhas'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarCampanha({
    required String nome,
    String? descricao,
    required int meta,
    required String dataValidade,
    String? dataInicio,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/empresas/me/campanhas'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        'meta': meta,
        'dataValidade': dataValidade,
        'dataInicio': ?dataInicio,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarStatusCampanha(String id, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/empresas/me/campanhas/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  /// Promoções = avisos/posts para os clientes (sem meta e sem cartão —
  /// quem gera cartão fidelidade é a campanha).
  Future<List<dynamic>> listarPromocoes() async {
    final res = await http.get(Uri.parse('$baseUrl/empresas/me/promocoes'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarPromocao({
    required String titulo,
    String? descricao,
    String? dataValidade,
    String? dataInicio,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/empresas/me/promocoes'),
      headers: _headers,
      body: jsonEncode({
        'titulo': titulo,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        'dataValidade': ?dataValidade,
        'dataInicio': ?dataInicio,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarStatusPromocao(String id, String status) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/empresas/me/promocoes/$id'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<void> excluirPromocao(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/empresas/me/promocoes/$id'), headers: _headers);
    await _handle(res);
  }

  Future<List<dynamic>> listarSolicitacoes({String? status, String? cpf, String? cupomFiscal}) async {
    final query = <String, String>{
      'status': ?status,
      if (cpf != null && cpf.isNotEmpty) 'cpf': cpf,
      if (cupomFiscal != null && cupomFiscal.isNotEmpty) 'cupomFiscal': cupomFiscal,
    };
    final uri = Uri.parse('$baseUrl/empresas/me/solicitacoes').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> resolverSolicitacao(String id, String acao) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/empresas/me/solicitacoes/$id'),
      headers: _headers,
      body: jsonEncode({'acao': acao}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> marcarManual(String cpf) async {
    final res = await http.post(
      Uri.parse('$baseUrl/empresas/me/solicitacoes/marcar-manual'),
      headers: _headers,
      body: jsonEncode({'cpf': cpf}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listarClientes() async {
    final res = await http.get(Uri.parse('$baseUrl/empresas/me/clientes'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> dashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/empresas/me/dashboard'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }
}
