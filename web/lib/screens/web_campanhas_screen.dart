import 'package:flutter/material.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../utils/vigencia.dart';
import '../widgets/web_sidebar.dart';

/// Painel administrativo (web) — listagem e gestão das campanhas de
/// fidelidade cadastradas. O botão "Nova Campanha" abre o formulário
/// já existente em [AdminSection.cadastro].
class WebCampanhasScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebCampanhasScreen({super.key, required this.onSelect});

  @override
  State<WebCampanhasScreen> createState() => _WebCampanhasScreenState();
}

class _WebCampanhasScreenState extends State<WebCampanhasScreen> {
  bool _carregando = true;
  String? _erro;
  List<dynamic> _campanhas = [];
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      final campanhas = await session.api.listarCampanhas();
      if (!mounted) return;
      setState(() => _campanhas = campanhas);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar as campanhas.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternarStatus(Map<String, dynamic> campanha) async {
    final novoStatus = campanha['status'] == 'ATIVA' ? 'EXPIRADA' : 'ATIVA';
    try {
      final session = EmpresaSessionScope.of(context);
      await session.api.atualizarStatusCampanha(campanha['id'] as String, novoStatus);
      await _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  List<dynamic> get _campanhasFiltradas {
    final busca = _buscaController.text.trim().toLowerCase();
    if (busca.isEmpty) return _campanhas;
    return _campanhas.where((c) => (c['nome'] as String).toLowerCase().contains(busca)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.campanhas,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 10),
            _buildHeader(context),
            const SizedBox(height: 26),
            if (_carregando)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_erro != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _carregar, child: const Text('Tentar de novo')),
                    ],
                  ),
                ),
              )
            else ...[
              _buildKpiRow(),
              const SizedBox(height: 20),
              _buildBusca(),
              const SizedBox(height: 16),
              _buildTable(),
            ],
            const SizedBox(height: 24),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text('Painel', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
        Text('Campanhas Criadas',
            style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 700;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Campanhas de Fidelidade',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Gerencie todas as campanhas ativas e encerradas da sua loja.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        );
        final actions = ElevatedButton.icon(
          onPressed: () => widget.onSelect(AdminSection.cadastro),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova Campanha'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        );
        if (wide) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: title), actions]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 16), actions]);
      },
    );
  }

  Widget _buildKpiRow() {
    final ativas = _campanhas.where((c) => statusEfetivo(c as Map<String, dynamic>) == 'ATIVA').length;
    final encerradas = _campanhas.where((c) => estaEncerrada(statusEfetivo(c as Map<String, dynamic>))).length;
    final cards = [
      _StatCard(icon: Icons.campaign_outlined, label: 'CAMPANHAS ATIVAS', value: '$ativas'),
      _StatCard(icon: Icons.event_busy_outlined, label: 'CAMPANHAS ENCERRADAS', value: '$encerradas'),
      _StatCard(icon: Icons.list_alt_outlined, label: 'TOTAL CADASTRADO', value: '${_campanhas.length}'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 700;
        if (wide) {
          return Row(children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 16),
            ],
          ]);
        }
        return Column(children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 14),
          ],
        ]);
      },
    );
  }

  Widget _buildBusca() {
    return TextField(
      controller: _buscaController,
      decoration: InputDecoration(
        hintText: 'Buscar campanha por nome...',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }

  Widget _buildTable() {
    final tipo = EmpresaConfigScope.of(context).tipoFidelidade;
    final campanhas = _campanhasFiltradas;
    return LayoutBuilder(
      builder: (context, c) {
        final tableWidth = c.maxWidth > 820 ? c.maxWidth : 820.0;
        return Container(
          decoration: _cardDecoration(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: const Row(children: [
                      _HeaderCell('CAMPANHA', flex: 3),
                      _HeaderCell('META', flex: 2),
                      _HeaderCell('PERÍODO', flex: 2),
                      _HeaderCell('STATUS', flex: 1),
                      _HeaderCell('AÇÕES', flex: 1),
                    ]),
                  ),
                  if (campanhas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Nenhuma campanha cadastrada ainda.', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  for (final item in campanhas)
                    _CampanhaRow(
                      campanha: item as Map<String, dynamic>,
                      tipo: tipo,
                      onAlternarStatus: () => _alternarStatus(item),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6)),
    );
  }
}

class _CampanhaRow extends StatelessWidget {
  final Map<String, dynamic> campanha;
  final TipoFidelidade tipo;
  final VoidCallback onAlternarStatus;
  const _CampanhaRow({required this.campanha, required this.tipo, required this.onAlternarStatus});

  @override
  Widget build(BuildContext context) {
    final efetivo = statusEfetivo(campanha);
    final apresentacao = apresentarStatus(efetivo);
    // "Encerrar" só faz sentido enquanto está gravada como ATIVA; "Reativar"
    // não adianta se o prazo já passou (ficaria Vencida de novo).
    final gravadaAtiva = campanha['status'] == 'ATIVA';
    final vencida = campanha['vencida'] == true;
    final unidade = tipo == TipoFidelidade.marcacoes ? 'marcações' : 'pontos';
    // Sem data de início gravada (campanhas antigas), vale desde o cadastro.
    final inicioStr = campanha['data_inicio'] != null
        ? formatarData(campanha['data_inicio'] as String)
        : formatarData(campanha['created_at'] as String, instante: true);
    final validadeStr = '$inicioStr a ${formatarData(campanha['data_validade'] as String)}';

    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFEFF2)))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(campanha['nome'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                if ((campanha['descricao'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 3),
                  Text(campanha['descricao'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text('${campanha['meta']} $unidade', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(validadeStr, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: apresentacao.fundo,
                borderRadius: BorderRadius.circular(99),
                border: apresentacao.fundo == AppColors.surface ? Border.all(color: AppColors.border) : null,
              ),
              child: Text(
                apresentacao.texto,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: apresentacao.cor),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              onPressed: (!gravadaAtiva && vencida) ? null : onAlternarStatus,
              icon: Icon(gravadaAtiva ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 20),
              tooltip: (!gravadaAtiva && vencida) ? 'Prazo vencido — crie uma nova campanha' : (gravadaAtiva ? 'Encerrar' : 'Reativar'),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
