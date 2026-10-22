import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApiException implements Exception {
  final String mensagem;
  final int? status;
  AdminApiException(this.mensagem, {this.status});
  @override
  String toString() => mensagem;
}

/// Cliente HTTP para o painel administrativo da 2RL (gestão de empresas,
/// planos, licenças e contratos). Fala direto com a API em produção —
/// não há ambiente de staging separado ainda.
class AdminApi {
  static const String baseUrl = 'https://api.acumulaai.com.br';

  /// Chamado quando uma requisição autenticada volta 401 (token vencido): o
  /// painel limpa a sessão e volta pro login.
  static void Function()? aoSessaoExpirar;

  final String? token;

  AdminApi({this.token});

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
    if (res.statusCode == 401 && token != null) aoSessaoExpirar?.call();
    throw AdminApiException(erro, status: res.statusCode);
  }

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/me'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listarEmpresas() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/empresas'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> detalheEmpresa(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/admin/empresas/$id'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> definirEmpresaPai(String id, String? empresaPaiId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/empresas/$id'),
      headers: _headers,
      body: jsonEncode({'empresaPaiId': empresaPaiId}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarEmpresa(String id, Map<String, dynamic> campos) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/empresas/$id'),
      headers: _headers,
      body: jsonEncode(campos),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listarPlanos() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/planos'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }

  Future<Map<String, dynamic>> criarPlano({
    required String nome,
    required double valorMensal,
    String? descricao,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/planos'),
      headers: _headers,
      body: jsonEncode({'nome': nome, 'valorMensal': valorMensal, 'descricao': descricao}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarPlano({
    required String id,
    String? nome,
    double? valorMensal,
    String? descricao,
    bool? ativo,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/planos/$id'),
      headers: _headers,
      body: jsonEncode({
        'nome': ?nome,
        'valorMensal': ?valorMensal,
        'descricao': ?descricao,
        'ativo': ?ativo,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> criarEmpresa({
    required String nome,
    required String cnpj,
    required String email,
    required String senha,
    required String descricaoRecompensa,
    String? categoria,
    String tipoFidelidade = 'MARCACOES',
    int metaFidelidade = 10,
    String? empresaPaiId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/empresas'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        'cnpj': cnpj,
        'email': email,
        'senha': senha,
        'descricaoRecompensa': descricaoRecompensa,
        'categoria': ?categoria,
        'tipoFidelidade': tipoFidelidade,
        'metaFidelidade': metaFidelidade,
        'empresaPaiId': ?empresaPaiId,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> criarLicenca({
    required String empresaId,
    required String planoId,
    required DateTime dataInicio,
    required DateTime dataVencimento,
    int diasTolerancia = 5,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/empresas/$empresaId/licencas'),
      headers: _headers,
      body: jsonEncode({
        'planoId': planoId,
        'dataInicio': dataInicio.toIso8601String(),
        'dataVencimento': dataVencimento.toIso8601String(),
        'diasTolerancia': diasTolerancia,
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarLicenca({
    required String licencaId,
    String? status,
    DateTime? dataVencimento,
  }) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/licencas/$licencaId'),
      headers: _headers,
      body: jsonEncode({
        'status': ?status,
        if (dataVencimento != null) 'dataVencimento': dataVencimento.toIso8601String(),
      }),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> criarContrato({required String empresaId, String? licencaId}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/empresas/$empresaId/contratos'),
      headers: _headers,
      body: jsonEncode({'licencaId': ?licencaId}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizarContrato({required String contratoId, required String status}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/admin/contratos/$contratoId'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resumoMonitoramento() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/monitoramento/resumo'), headers: _headers);
    return await _handle(res) as Map<String, dynamic>;
  }

  Future<List<dynamic>> usoPorEmpresa() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/monitoramento/uso-por-empresa'), headers: _headers);
    return await _handle(res) as List<dynamic>;
  }
}
