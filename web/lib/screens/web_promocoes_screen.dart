import 'package:flutter/material.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../utils/vigencia.dart';
import '../widgets/web_sidebar.dart';

/// Painel administrativo (web) — avisos/posts que a loja publica para os
/// clientes vinculados (aba "Promoções" do app). Promoção NÃO é campanha:
/// não tem meta e não gera cartão fidelidade — quem gera cartão é a tela
/// "Campanhas".
class WebPromocoesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebPromocoesScreen({super.key, required this.onSelect});

  @override
  State<WebPromocoesScreen> createState() => _WebPromocoesScreenState();
}

class _WebPromocoesScreenState extends State<WebPromocoesScreen> {
  bool _carregando = true;
  String? _erro;
  List<dynamic> _promocoes = [];
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
      final campanhas = await session.api.listarPromocoes();
      if (!mounted) return;
      setState(() => _promocoes = campanhas);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar as promoções.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _excluir(Map<String, dynamic> promocao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir promoção?'),
        content: Text('"${promocao['titulo']}" deixará de aparecer no app dos clientes. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      final session = EmpresaSessionScope.of(context);
      await session.api.excluirPromocao(promocao['id'] as String);
      await _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _alternarStatus(Map<String, dynamic> campanha) async {
    final novoStatus = campanha['status'] == 'ATIVA' ? 'EXPIRADA' : 'ATIVA';
    try {
      final session = EmpresaSessionScope.of(context);
      await session.api.atualizarStatusPromocao(campanha['id'] as String, novoStatus);
      await _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  List<dynamic> get _filtradas {
    switch (_filter) {
      case _Filter.todas:
        return _promocoes;
      case _Filter.ativas:
        return _promocoes.where((c) => !estaEncerrada(statusEfetivo(c as Map<String, dynamic>))).toList();
      case _Filter.expiradas:
        return _promocoes.where((c) => estaEncerrada(statusEfetivo(c as Map<String, dynamic>))).toList();
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
                  onAlternarStatus: () => _alternarStatus(campanha),
                  onExcluir: () => _excluir(campanha),
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
            const Text('Avisos e ofertas que aparecem na aba Promoções do app dos seus clientes. Não geram cartão fidelidade — para isso, crie uma Campanha.',
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
          _FilterTab(label: 'Todas (${_promocoes.length})', selected: _filter == _Filter.todas, onTap: () => setState(() => _filter = _Filter.todas)),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Ativas (${_promocoes.where((c) => !estaEncerrada(statusEfetivo(c as Map<String, dynamic>))).length})',
            dotColor: AppColors.success,
            selected: _filter == _Filter.ativas,
            onTap: () => setState(() => _filter = _Filter.ativas),
          ),
          const SizedBox(width: 8),
          _FilterTab(
            label: 'Encerradas (${_promocoes.where((c) => estaEncerrada(statusEfetivo(c as Map<String, dynamic>))).length})',
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
  final VoidCallback onAlternarStatus;
  final VoidCallback onExcluir;
  const _PromoCard({required this.campanha, required this.onAlternarStatus, required this.onExcluir});

  @override
  Widget build(BuildContext context) {
    final apresentacao = apresentarStatus(statusEfetivo(campanha));
    // Gravada como ATIVA = dá pra encerrar; senão dá pra reativar (a não ser que o prazo já tenha passado).
    final ativa = campanha['status'] == 'ATIVA';
    final vencida = campanha['vencida'] == true;
    // Período de validade: início (sem ele, vale desde o cadastro) e fim opcional.
    final inicioStr = campanha['data_inicio'] != null
        ? formatarData(campanha['data_inicio'] as String)
        : formatarData(campanha['created_at'] as String, instante: true);
    final fimBruto = campanha['data_validade'] as String?;
    final validadeStr = fimBruto == null ? 'Desde $inicioStr · sem data limite' : '$inicioStr a ${formatarData(fimBruto)}';

    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 640;
            final image = _buildImage();
            final body = _buildBody(apresentacao, ativa, vencida, validadeStr);
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

  Widget _buildBody(ApresentacaoStatus apresentacao, bool ativa, bool vencida, String validadeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: apresentacao.cor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(apresentacao.texto, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: apresentacao.cor)),
            const SizedBox(width: 14),
            const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('Válida: $validadeStr', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        Text(campanha['titulo'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        if ((campanha['descricao'] as String?)?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(campanha['descricao'] as String, style: const TextStyle(fontSize: 13.5, color: AppColors.textDark, height: 1.4)),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(
          onPressed: (!ativa && vencida) ? null : onAlternarStatus,
          icon: Icon(ativa ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 16),
          label: Text(ativa ? 'Encerrar' : (vencida ? 'Prazo vencido' : 'Reativar')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textDark,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onExcluir,
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Excluir'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        ]),
      ],
    );
  }
}
