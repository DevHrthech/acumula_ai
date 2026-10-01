import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Mecânica de fidelidade da loja — decisão documentada em
/// docs/MECANICA_FIDELIDADE.md. Fixa após o cadastro (não deve ser trocada
/// com clientes já ativos).
enum TipoFidelidade { marcacoes, pontos }

/// Só relevante para lojas com [TipoFidelidade.pontos]. O critério de quando
/// cada regra se aplica ainda não foi definido (ver MECANICA_FIDELIDADE.md
/// seção 4) — por ora é só descrição + pontos.
class RegraPontuacao {
  final String descricao;
  final int pontos;
  const RegraPontuacao({required this.descricao, required this.pontos});
}

/// Configuração da loja, compartilhada entre as telas do painel Web.
/// Ainda sem persistência real (server/ fora de escopo por ora) — vive só
/// em memória durante a sessão do app.
class EmpresaConfig extends ChangeNotifier {
  String nome = '';
  String categoria = '';
  TipoFidelidade tipoFidelidade = TipoFidelidade.marcacoes;
  int metaFidelidade = 10;
  String descricaoRecompensa = '';

  String? iconeUrl;
  String? logoQrCodeUrl;
  String? logoPromocaoUrl;

  /// Cores da marca, aplicadas ao cartão fidelidade que o cliente vê no app
  /// (mobile/ ainda não lê isso — fica pronto pra quando a customização
  /// visual completa, adiada no SPEC seção 5, for retomada).
  Color corPrincipal = AppColors.primary;
  Color corDestaque = AppColors.accent;

  /// Textos personalizados que o cliente final vê no app (mobile/ ainda não
  /// lê isso — fica pronto pra quando a customização de textos/botões for
  /// retomada do lado do cliente).
  String nomePrograma = 'Cartão Fidelidade';
  String mensagemBoasVindas =
      'Bem-vindo(a)! Comece a acumular suas recompensas.';
  String mensagemResgate = 'Parabéns! Sua recompensa foi resgatada.';
  String textoBotaoResgate = 'Resgatar recompensa';

  final List<RegraPontuacao> regrasPontuacao = [
    const RegraPontuacao(descricao: 'Padrão (por marcação)', pontos: 10),
  ];

  String get metaLabel =>
      tipoFidelidade == TipoFidelidade.marcacoes ? 'marcações' : 'pontos';

  String get metaLabelCapitalizado =>
      tipoFidelidade == TipoFidelidade.marcacoes ? 'Marcações' : 'Pontos';

  /// Popula a partir do JSON de `GET/PATCH /empresas/me` (ver
  /// server/src/routes/empresa.js) — chamado após login e após salvar,
  /// pra sincronizar o estado local com o que a API confirmou ter gravado.
  void carregarDe(Map<String, dynamic> dados) {
    nome = dados['nome'] as String;
    categoria = (dados['categoria'] as String?) ?? categoria;
    tipoFidelidade = (dados['tipo_fidelidade'] as String) == 'PONTOS'
        ? TipoFidelidade.pontos
        : TipoFidelidade.marcacoes;
    metaFidelidade = dados['meta_fidelidade'] as int;
    descricaoRecompensa = dados['descricao_recompensa'] as String;
    iconeUrl = dados['icone_url'] as String?;
    logoQrCodeUrl = dados['logo_qrcode_url'] as String?;
    logoPromocaoUrl = dados['logo_promocao_url'] as String?;
    corPrincipal = _corDeHex(dados['cor_principal'] as String);
    corDestaque = _corDeHex(dados['cor_destaque'] as String);
    AppColors.applyBrandColors(principal: corPrincipal, destaque: corDestaque);
    nomePrograma = dados['nome_programa'] as String;
    mensagemBoasVindas = (dados['mensagem_boas_vindas'] as String?) ?? '';
    mensagemResgate = (dados['mensagem_resgate'] as String?) ?? '';
    textoBotaoResgate = dados['texto_botao_resgate'] as String;
    notifyListeners();
  }

  /// Mecânica e regras de pontuação ainda não voltam do `PATCH /empresas/me`
  /// (sem suporte no servidor ainda, ver docs/MECANICA_FIDELIDADE.md) — usado
  /// pra manter a seleção da loja na tela nesta sessão, sem perder ao salvar
  /// os outros campos (que carregarDe() já atualiza a partir da API).
  void aplicarSelecaoLocal({
    required TipoFidelidade tipoFidelidade,
    required List<RegraPontuacao> regrasPontuacao,
  }) {
    this.tipoFidelidade = tipoFidelidade;
    this.regrasPontuacao
      ..clear()
      ..addAll(regrasPontuacao);
    notifyListeners();
  }

  static Color _corDeHex(String hex) {
    final valor = hex.replaceFirst('#', '');
    return Color(int.parse('FF$valor', radix: 16));
  }

  void salvar({
    required String nome,
    required String categoria,
    required TipoFidelidade tipoFidelidade,
    required int metaFidelidade,
    required String descricaoRecompensa,
    required List<RegraPontuacao> regrasPontuacao,
    required Color corPrincipal,
    required Color corDestaque,
    required String nomePrograma,
    required String mensagemBoasVindas,
    required String mensagemResgate,
    required String textoBotaoResgate,
  }) {
    this.nome = nome;
    this.categoria = categoria;
    this.tipoFidelidade = tipoFidelidade;
    this.metaFidelidade = metaFidelidade;
    this.descricaoRecompensa = descricaoRecompensa;
    this.regrasPontuacao
      ..clear()
      ..addAll(regrasPontuacao);
    this.corPrincipal = corPrincipal;
    this.corDestaque = corDestaque;
    AppColors.applyBrandColors(principal: corPrincipal, destaque: corDestaque);
    this.nomePrograma = nomePrograma;
    this.mensagemBoasVindas = mensagemBoasVindas;
    this.mensagemResgate = mensagemResgate;
    this.textoBotaoResgate = textoBotaoResgate;
    notifyListeners();
  }
}

class EmpresaConfigScope extends StatefulWidget {
  final Widget child;

  const EmpresaConfigScope({super.key, required this.child});

  @override
  State<EmpresaConfigScope> createState() => EmpresaConfigScopeState();

  static EmpresaConfig of(BuildContext context) {
    final EmpresaConfigScopeState? state =
        context.findAncestorStateOfType<EmpresaConfigScopeState>();
    assert(state != null, 'No EmpresaConfigScope found in context');
    return state!.empresaConfig;
  }
}

class EmpresaConfigScopeState extends State<EmpresaConfigScope> {
  late final EmpresaConfig empresaConfig;

  @override
  void initState() {
    super.initState();
    empresaConfig = EmpresaConfig();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: empresaConfig,
      builder: (context, child) => _InheritedEmpresaConfigScope(
        empresaConfig: empresaConfig,
        child: widget.child,
      ),
    );
  }
}

class _InheritedEmpresaConfigScope extends InheritedWidget {
  final EmpresaConfig empresaConfig;

  const _InheritedEmpresaConfigScope({
    required this.empresaConfig,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedEmpresaConfigScope oldWidget) {
    return empresaConfig != oldWidget.empresaConfig;
  }
}
