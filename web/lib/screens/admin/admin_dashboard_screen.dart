import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../utils/admin_status.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_empresa_detalhe_screen.dart';

/// Dashboard financeiro da 2RL: faturamento por período, receita recorrente,
/// a receber, atrasos, empresas por situação e conversão do trial (cobrança
/// via Asaas). Os números vêm prontos de GET /admin/financeiro.
class AdminDashboardScreen extends StatefulWidget {
  final AdminSession session;
  const AdminDashboardScreen({super.key, required this.session});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _periodos = [
    ('mes', 'Este mês'),
    ('3m', '3 meses'),
    ('6m', '6 meses'),
    ('12m', '12 meses'),
    ('ano', 'Este ano'),
  ];

  String _periodo = '6m';
  Map<String, dynamic>? _dados;
  String? _erro;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _erro = null;
      _carregando = true;
    });
    try {
      final dados = await widget.session.api.financeiro(_periodo);
      if (!mounted) return;
      setState(() => _dados = dados);
    } on AdminApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível carregar o dashboard.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _abrirEmpresa(String id) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AdminEmpresaDetalheScreen(session: widget.session, empresaId: id)))
        .then((_) => _carregar());
  }

  String _reais(num v) => 'R\$ ${formatarMoeda(v)}';

  /// "2026-11" -> "nov/26".
  String _mesCurto(String chave) {
    const nomes = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    final p = chave.split('-');
    return '${nomes[int.parse(p[1]) - 1]}/${p[0].substring(2)}';
  }

  String _dataCurta(String iso) {
    final p = iso.substring(0, 10).split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_dados == null && _erro == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_dados == null) {
      return Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)));
    }

    final d = _dados!;
    final k = d['kpis'] as Map<String, dynamic>;
    final periodo = d['periodo'] as Map<String, dynamic>;
    final variacao = k['variacao_mes_pct'] as num?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            titulo: 'Dashboard',
            subtitulo: 'Faturamento, receita recorrente e situação das empresas (cobrança via Asaas).',
            acoes: [
              AdminIconButton(icone: Icons.refresh, onPressed: _carregar, tooltip: 'Atualizar'),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (chave, rotulo) in _periodos)
                      ChoiceChip(
                        label: Text(rotulo),
                        selected: _periodo == chave,
                        onSelected: (_) {
                          setState(() => _periodo = chave);
                          _carregar();
                        },
                      ),
                  ],
                ),
              ),
              if (_carregando) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Text(
                '${_dataCurta(periodo['de'] as String)} a ${_dataCurta(periodo['ate'] as String)}',
                style: TextStyle(fontSize: 12.5, color: theme.textMuted),
              ),
            ],
          ),
          if (_erro != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(
                titulo: 'FATURAMENTO NO PERÍODO',
                valor: _reais(k['faturamento_periodo'] as num),
                icone: Icons.payments_outlined,
                corIcone: theme.success,
                largura: 262,
                legenda: '${k['pagamentos_periodo']} pagamentos · ticket ${_reais(k['ticket_medio'] as num)}',
              ),
              AdminStatCard(
                titulo: 'RECEBIDO NO MÊS ATUAL',
                valor: _reais(k['faturamento_mes_atual'] as num),
                icone: Icons.calendar_month_outlined,
                corIcone: theme.primary,
                largura: 262,
                legenda: variacao == null
                    ? 'Sem base de comparação'
                    : '${variacao >= 0 ? '▲' : '▼'} ${variacao.abs().toStringAsFixed(1).replaceAll('.', ',')}% vs mês anterior',
                corLegenda: variacao == null ? theme.textMuted : (variacao >= 0 ? theme.success : theme.danger),
              ),
              AdminStatCard(
                titulo: 'RECEITA RECORRENTE (MRR)',
                valor: _reais(k['mrr'] as num),
                icone: Icons.autorenew,
                corIcone: theme.primary,
                largura: 262,
                legenda: '${k['assinantes_pagantes']} assinantes pagantes',
              ),
              AdminStatCard(
                titulo: 'A RECEBER',
                valor: _reais(k['a_receber'] as num),
                icone: Icons.schedule_outlined,
                corIcone: theme.warning,
                largura: 262,
                legenda: '${k['faturas_a_receber']} ${k['faturas_a_receber'] == 1 ? 'fatura em aberto' : 'faturas em aberto'}',
              ),
              AdminStatCard(
                titulo: 'EM ATRASO',
                valor: _reais(k['em_atraso'] as num),
                icone: Icons.warning_amber_outlined,
                corIcone: theme.danger,
                largura: 262,
                legenda: '${k['faturas_em_atraso']} ${k['faturas_em_atraso'] == 1 ? 'fatura atrasada' : 'faturas atrasadas'}',
                corLegenda: (k['faturas_em_atraso'] as int) > 0 ? theme.danger : theme.textMuted,
              ),
              AdminStatCard(
                titulo: 'PREVISÃO DOS TESTES',
                valor: _reais(k['previsao_trials'] as num),
                icone: Icons.card_giftcard_outlined,
                corIcone: theme.primary,
                largura: 262,
                legenda: 'Por mês, se todos os testes converterem',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _duasColunas(
            _cardFaturamentoMensal(theme, (d['serie_mensal'] as List<dynamic>).cast<Map<String, dynamic>>()),
            _cardSituacoes(theme, d['empresas'] as Map<String, dynamic>, d['conversao_trial'] as Map<String, dynamic>),
            pesoEsquerda: 3,
            pesoDireita: 2,
          ),
          const SizedBox(height: 20),
          _duasColunas(
            _cardPorPlano(theme, (d['por_plano'] as List<dynamic>).cast<Map<String, dynamic>>()),
            _cardPorForma(theme, (d['por_forma'] as List<dynamic>).cast<Map<String, dynamic>>()),
          ),
          const SizedBox(height: 20),
          _cardFaturas(
            theme,
            icone: Icons.warning_amber_outlined,
            cor: theme.danger,
            titulo: 'Faturas em atraso',
            subtitulo: 'Empresas com mensalidade vencida e não paga',
            vazio: 'Nenhuma fatura em atraso.',
            faturas: (d['faturas_em_atraso'] as List<dynamic>).cast<Map<String, dynamic>>(),
            atrasadas: true,
          ),
          const SizedBox(height: 20),
          _duasColunas(
            _cardFaturas(
              theme,
              icone: Icons.event_outlined,
              cor: theme.warning,
              titulo: 'Próximos vencimentos',
              subtitulo: 'Faturas que vencem nos próximos 30 dias',
              vazio: 'Nenhuma fatura vence nos próximos 30 dias.',
              faturas: (d['proximos_vencimentos'] as List<dynamic>).cast<Map<String, dynamic>>(),
              atrasadas: false,
            ),
            _cardTrials(theme, (d['trials_terminando'] as List<dynamic>).cast<Map<String, dynamic>>()),
          ),
        ],
      ),
    );
  }

  Widget _duasColunas(Widget esquerda, Widget direita, {int pesoEsquerda = 1, int pesoDireita = 1}) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [esquerda, const SizedBox(height: 20), direita]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: pesoEsquerda, child: esquerda),
            const SizedBox(width: 20),
            Expanded(flex: pesoDireita, child: direita),
          ],
        );
      },
    );
  }

  // ---- faturamento por mês -------------------------------------------------

  Widget _cardFaturamentoMensal(ThemeProvider theme, List<Map<String, dynamic>> serie) {
    final maior = serie.fold<double>(0, (m, s) {
      final a = (s['recebido'] as num).toDouble();
      final b = (s['em_aberto'] as num).toDouble();
      return [m, a, b].reduce((x, y) => x > y ? x : y);
    });
    final teto = maior <= 0 ? 1.0 : maior;
    const altura = 190.0;

    return AdminSectionCard(
      icone: Icons.bar_chart_rounded,
      corIcone: theme.primary,
      titulo: 'Faturamento por mês',
      subtitulo: 'Recebido (pela data de pagamento) e em aberto (pelo vencimento)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Legenda(cor: theme.primary, texto: 'Recebido'),
              const SizedBox(width: 18),
              _Legenda(cor: theme.warning.withValues(alpha: 0.55), texto: 'Em aberto'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: altura + 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final s in serie)
                  Expanded(
                    child: Tooltip(
                      message: '${_mesCurto(s['mes'] as String)}\nRecebido: ${_reais(s['recebido'] as num)}\nEm aberto: ${_reais(s['em_aberto'] as num)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: altura,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Barra(valor: (s['recebido'] as num).toDouble(), teto: teto, altura: altura, cor: theme.primary, rotulo: _reais(s['recebido'] as num), corTexto: theme.textDark),
                                const SizedBox(width: 4),
                                _Barra(valor: (s['em_aberto'] as num).toDouble(), teto: teto, altura: altura, cor: theme.warning.withValues(alpha: 0.55), rotulo: null, corTexto: theme.textMuted),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_mesCurto(s['mes'] as String), style: TextStyle(fontSize: 11.5, color: theme.textMuted, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- empresas por situação ----------------------------------------------

  Widget _cardSituacoes(ThemeProvider theme, Map<String, dynamic> empresas, Map<String, dynamic> conversao) {
    final total = empresas['total'] as int;
    const ordem = ['PAGA', 'ATIVA_MANUAL', 'EM_TESTE', 'ATRASADA', 'BLOQUEADA', 'CANCELADA', 'SEM_LICENCA'];
    final taxa = conversao['taxa_pct'] as num?;

    return AdminSectionCard(
      icone: Icons.donut_large_outlined,
      corIcone: theme.primary,
      titulo: 'Empresas por situação',
      subtitulo: '$total empresas cadastradas',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final chave in ordem)
            if ((empresas[chave] as int) > 0 || chave == 'PAGA' || chave == 'EM_TESTE' || chave == 'ATRASADA')
              Builder(builder: (context) {
                final qtd = empresas[chave] as int;
                final ap = apresentarSituacaoFinanceira(theme, chave);
                final cor = chave == 'SEM_LICENCA' || chave == 'CANCELADA' ? theme.textMuted : ap.cor;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 96, child: AdminBadge(texto: ap.texto.toUpperCase(), cor: ap.cor, fundo: ap.fundo)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : qtd / total,
                            minHeight: 8,
                            backgroundColor: theme.border.withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation(cor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(width: 28, child: Text('$qtd', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textDark))),
                    ],
                  ),
                );
              }),
          const Divider(height: 24),
          Text('CONVERSÃO DO TESTE GRÁTIS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          Text(
            taxa == null ? 'Sem testes encerrados ainda' : '${taxa.toStringAsFixed(1).replaceAll('.', ',')}% viraram assinantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            '${conversao['convertidos']} convertidos · ${conversao['em_andamento']} em andamento · '
            '${conversao['iniciados_no_periodo']} iniciados no período',
            style: TextStyle(fontSize: 12.5, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  // ---- por plano / por forma -------------------------------------------------

  Widget _cardPorPlano(ThemeProvider theme, List<Map<String, dynamic>> planos) {
    return AdminSectionCard(
      icone: Icons.card_membership_outlined,
      corIcone: theme.primary,
      titulo: 'Receita por plano',
      subtitulo: 'Assinantes pagantes e receita mensal recorrente',
      child: planos.isEmpty
          ? const AdminEmptyState(icone: Icons.card_membership_outlined, titulo: 'Sem assinantes pagantes', descricao: 'Os planos aparecem aqui quando houver empresas pagando.')
          : Column(
              children: [
                for (final p in planos)
                  _LinhaSimples(
                    titulo: p['plano'] as String,
                    detalhe: '${p['assinantes']} ${p['assinantes'] == 1 ? 'assinante' : 'assinantes'}',
                    valor: '${_reais(p['receita_mensal'] as num)}/mês',
                  ),
              ],
            ),
    );
  }

  Widget _cardPorForma(ThemeProvider theme, List<Map<String, dynamic>> formas) {
    String rotulo(String f) => switch (f) {
          'PIX' => 'Pix',
          'CREDIT_CARD' => 'Cartão de crédito',
          'BOLETO' => 'Boleto',
          _ => 'Outras',
        };
    return AdminSectionCard(
      icone: Icons.account_balance_wallet_outlined,
      corIcone: theme.primary,
      titulo: 'Recebido por forma de pagamento',
      subtitulo: 'No período selecionado',
      child: formas.isEmpty
          ? const AdminEmptyState(icone: Icons.account_balance_wallet_outlined, titulo: 'Nenhum recebimento no período', descricao: 'Os valores recebidos por Pix e cartão aparecem aqui.')
          : Column(
              children: [
                for (final f in formas)
                  _LinhaSimples(
                    titulo: rotulo(f['forma'] as String),
                    detalhe: '${f['quantidade']} ${f['quantidade'] == 1 ? 'pagamento' : 'pagamentos'}',
                    valor: _reais(f['total'] as num),
                  ),
              ],
            ),
    );
  }

  // ---- listas ------------------------------------------------------------------

  Widget _cardFaturas(
    ThemeProvider theme, {
    required IconData icone,
    required Color cor,
    required String titulo,
    required String subtitulo,
    required String vazio,
    required List<Map<String, dynamic>> faturas,
    required bool atrasadas,
  }) {
    return AdminSectionCard(
      icone: icone,
      corIcone: cor,
      titulo: titulo,
      subtitulo: subtitulo,
      child: faturas.isEmpty
          ? AdminEmptyState(icone: Icons.check_circle_outline, titulo: vazio, descricao: 'Tudo em dia por aqui.')
          : Column(
              children: [
                for (final f in faturas)
                  _LinhaSimples(
                    titulo: f['empresa'] as String,
                    detalhe: atrasadas
                        ? 'Venceu em ${_dataCurta(f['data_vencimento'] as String)} · ${f['dias_atraso']} ${f['dias_atraso'] == 1 ? 'dia' : 'dias'} de atraso'
                        : 'Vence em ${_dataCurta(f['data_vencimento'] as String)}',
                    valor: _reais(f['valor'] as num),
                    corValor: atrasadas ? theme.danger : null,
                    onTap: () => _abrirEmpresa(f['empresa_id'] as String),
                  ),
              ],
            ),
    );
  }

  Widget _cardTrials(ThemeProvider theme, List<Map<String, dynamic>> trials) {
    return AdminSectionCard(
      icone: Icons.card_giftcard_outlined,
      corIcone: theme.primary,
      titulo: 'Testes terminando',
      subtitulo: 'Empresas cujo teste grátis acaba em até 7 dias',
      child: trials.isEmpty
          ? const AdminEmptyState(icone: Icons.hourglass_empty, titulo: 'Nenhum teste terminando', descricao: 'Nenhuma empresa está perto do fim do teste grátis.')
          : Column(
              children: [
                for (final t in trials)
                  _LinhaSimples(
                    titulo: t['empresa'] as String,
                    detalhe: '${t['plano']} · termina em ${_dataCurta(t['data_vencimento'] as String)}',
                    valor: t['dias_restantes'] == 0 ? 'Hoje' : '${t['dias_restantes']} ${t['dias_restantes'] == 1 ? 'dia' : 'dias'}',
                    onTap: () => _abrirEmpresa(t['empresa_id'] as String),
                  ),
              ],
            ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;
  const _Legenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Barra do gráfico; `rotulo` (valor) aparece acima quando a barra existe.
class _Barra extends StatelessWidget {
  final double valor;
  final double teto;
  final double altura;
  final Color cor;
  final String? rotulo;
  final Color corTexto;

  const _Barra({required this.valor, required this.teto, required this.altura, required this.cor, required this.rotulo, required this.corTexto});

  @override
  Widget build(BuildContext context) {
    final h = valor <= 0 ? 2.0 : (valor / teto * (altura - 18)).clamp(3.0, altura - 18);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rotulo != null && valor > 0)
          Text(rotulo!.replaceFirst('R\$ ', ''), style: TextStyle(fontSize: 9.5, color: corTexto, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Container(
          width: 18,
          height: h,
          decoration: BoxDecoration(color: cor, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
        ),
      ],
    );
  }
}

class _LinhaSimples extends StatelessWidget {
  final String titulo;
  final String detalhe;
  final String valor;
  final Color? corValor;
  final VoidCallback? onTap;

  const _LinhaSimples({required this.titulo, required this.detalhe, required this.valor, this.corValor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.bgPage,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.border)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, color: theme.textDark, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(detalhe, style: TextStyle(fontSize: 12, color: theme.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(valor, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: corValor ?? theme.textDark)),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 18, color: theme.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
