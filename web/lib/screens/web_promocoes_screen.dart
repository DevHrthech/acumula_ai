import 'package:flutter/material.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

/// Painel administrativo (web) — vitrine das campanhas de fidelidade em
/// formato de cards (mesma entidade da tela "Campanhas", ver
/// docs/MECANICA_FIDELIDADE.md e docs/SPEC.md seção 14: "Promoções" não é
/// um recurso separado, é outra visualização das mesmas campanhas).
class WebPromocoesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebPromocoesScreen({super.key, required this.onSelect});

  @override
  State<WebPromocoesScreen> createState() => _WebPromocoesScreenState();
}

class _WebPromocoesScreenState extends State<WebPromocoesScreen> {
  bool _carregando = true;
  String? _erro;
  List<dynamic> _campanhas = [];
  _Filter _filter = _Filter.todas;

  @override
  void initState() {
    super.initState();
    _carregar();
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
      setState(() => _erro = 'Não foi possível carregar as promoções.');
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

  List<dynamic> get _filtradas {
    switch (_filter) {
      case _Filter.todas:
        return _campanhas;
      case _Filter.ativas:
        return _campanhas.where((c) => c['status'] == 'ATIVA').toList();
      case _Filter.expiradas:
        return _campanhas.where((c) => c['status'] == 'EXPIRADA').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.promocoes,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEyebrow(),
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 24),
            if (_carregando)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_erro != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Text(_erro!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _carregar, child: const Text('Tentar de novo')),
                  ]),
                ),
              )
            else ...[
              _buildFilterBar(),
              const SizedBox(height: 18),
              if (_filtradas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('Nenhuma promoção nesse filtro.', style: TextStyle(color: AppColors.textMuted))),
                ),
              for (final campanha in _filtradas) ...[
                _PromoCard(
                  campanha: campanha as Map<String, dynamic>,
                  tipo: EmpresaConfigScope.of(context).tipoFidelidade,
                  onAlternarStatus: () => _alternarStatus(campanha),
                ),
                const SizedBox(height: 18),
              ],
            ],
            const SizedBox(height: 24),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEyebrow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.campaign, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text('GESTÃO DE ENGAJAMENTO',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 700;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Promoções Anunciadas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 4),
            const Text('Vitrine das suas campanhas de fidelidade ativas para os clientes.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
          ],
        );
        final action = ElevatedButton.icon(
          onPressed: () => widget.onSelect(AdminSection.postar),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova Promoção'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        );
        if (wide) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: title), action]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 16), action]);
      },
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterTab(label: 'Todas (${_campanhas.length})', selected: _filter == _Filter.todas, onTap: () => setState(() => _filter = _Filter.todas)),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Ativas (${_campanhas.where((c) => c['status'] == 'ATIVA').length})',
            dotColor: AppColors.success,
            selected: _filter == _Filter.ativas,
            onTap: () => setState(() => _filter = _Filter.ativas),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Expiradas (${_campanhas.where((c) => c['status'] == 'EXPIRADA').length})',
            selected: _filter == _Filter.expiradas,
            onTap: () => setState(() => _filter = _Filter.expiradas),
          ),
        ],
      ),
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

enum _Filter { todas, ativas, expiradas }

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.selected, required this.onTap, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                const SizedBox(width: 7),
              ],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> campanha;
  final TipoFidelidade tipo;
  final VoidCallback onAlternarStatus;
  const _PromoCard({required this.campanha, required this.tipo, required this.onAlternarStatus});

  @override
  Widget build(BuildContext context) {
    final ativa = campanha['status'] == 'ATIVA';
    final unidade = tipo == TipoFidelidade.marcacoes ? 'marcações' : 'pontos';
    final validade = DateTime.parse(campanha['data_validade'] as String);
    final validadeStr = '${validade.day.toString().padLeft(2, '0')}/${validade.month.toString().padLeft(2, '0')}/${validade.year}';

    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 640;
            final image = _buildImage();
            final body = _buildBody(ativa, unidade, validadeStr);
            if (wide) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [image, const SizedBox(width: 18), Expanded(child: body)]);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SizedBox(width: double.infinity, child: image), const SizedBox(height: 14), body],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
        ),
        child: const Center(child: Icon(Icons.campaign_outlined, color: Colors.white70, size: 40)),
      ),
    );
  }

  Widget _buildBody(bool ativa, String unidade, String validadeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: ativa ? AppColors.success : AppColors.textMuted, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(ativa ? 'Ativa' : 'Encerrada', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ativa ? AppColors.success : AppColors.textMuted)),
            const SizedBox(width: 14),
            const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Válida até $validadeStr', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        Text(campanha['nome'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        if ((campanha['descricao'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(campanha['descricao'] as String, style: const TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.4)),
        ],
        const SizedBox(height: 8),
        Text('Meta: ${campanha['meta']} $unidade', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAlternarStatus,
          icon: Icon(ativa ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
          label: Text(ativa ? 'Encerrar' : 'Reativar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textDark,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
