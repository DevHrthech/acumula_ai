import 'package:flutter/material.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

/// Aprovação de compras/marcações. Diferente da antiga tela de moderação de
/// campanhas (removida — aprovação de campanha é automática, ver
/// docs/MECANICA_FIDELIDADE.md). Esta tela trata da fila de solicitações que
/// o cliente faz pelo app (com ou sem número de cupom fiscal) e da opção da
/// loja marcar uma compra diretamente, buscando pelo CPF do cliente.
class WebAprovacaoScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebAprovacaoScreen({super.key, required this.onSelect});

  @override
  State<WebAprovacaoScreen> createState() => _WebAprovacaoScreenState();
}

class _WebAprovacaoScreenState extends State<WebAprovacaoScreen> {
  final _busca = TextEditingController();
  final _cpfManual = TextEditingController();
  int _filtro = 0;
  bool _marcandoManualmente = false;
  bool _enviandoManual = false;
  bool _carregando = true;
  String? _erro;
  List<dynamic> _solicitacoes = [];
  static const _filtros = ['Todas', 'Pendentes', 'Aprovadas', 'Rejeitadas'];
  static const _statusPorFiltro = [null, 'PENDENTE', 'APROVADA', 'REJEITADA'];

  @override
  void initState() {
    super.initState();
    _busca.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _busca.dispose();
    _cpfManual.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      final solicitacoes = await session.api.listarSolicitacoes(status: _statusPorFiltro[_filtro]);
      if (!mounted) return;
      setState(() => _solicitacoes = solicitacoes);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar as solicitações.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<dynamic> get _visiveis {
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isEmpty) return _solicitacoes;
    return _solicitacoes.where((s) {
      final cliente = s['cliente'] as Map<String, dynamic>;
      final cupom = (s['cupomFiscal'] as String? ?? '').toLowerCase();
      final cpf = cliente['cpf'] as String;
      return cpf.contains(termo) || cupom.contains(termo);
    }).toList();
  }

  Future<void> _resolver(Map<String, dynamic> s, String acao) async {
    try {
      final session = EmpresaSessionScope.of(context);
      final resultado = await session.api.resolverSolicitacao(s['id'] as String, acao);
      if (!mounted) return;
      final nome = (s['cliente'] as Map<String, dynamic>)['nome'] as String;
      final msg = acao == 'aprovar'
          ? '$nome: marcação registrada.${resultado['recompensaLiberada'] == true ? ' Recompensa liberada! 🎉' : ''}'
          : 'Solicitação de $nome rejeitada.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    }
  }

  Future<void> _marcarManualmente() async {
    final cpf = _cpfManual.text.trim();
    if (cpf.isEmpty) return;
    setState(() => _enviandoManual = true);
    try {
      final session = EmpresaSessionScope.of(context);
      final resultado = await session.api.marcarManual(cpf);
      if (!mounted) return;
      final nome = (resultado['cliente'] as Map<String, dynamic>)['nome'] as String;
      setState(() {
        _cpfManual.clear();
        _marcandoManualmente = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$nome: marcação registrada.${resultado['recompensaLiberada'] == true ? ' Recompensa liberada! 🎉' : ''}')),
      );
      await _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    } finally {
      if (mounted) setState(() => _enviandoManual = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.aprovacao,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebPageHeader(
              title: 'Aprovação de compras',
              subtitle: 'Confirme as compras que seus clientes solicitaram pelo app, ou registre uma marcação diretamente pelo CPF.',
              searchHint: 'Buscar por CPF ou número do cupom fiscal',
              searchController: _busca,
              primaryActionLabel: 'Marcar compra manualmente',
              primaryActionIcon: Icons.add,
              onPrimaryAction: () => setState(() => _marcandoManualmente = true),
            ),
            const SizedBox(height: 24),
            if (_marcandoManualmente) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CPF do cliente', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cpfManual,
                            decoration: InputDecoration(
                              hintText: '000.000.000-00',
                              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                              filled: true,
                              fillColor: AppColors.inputBg,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.4)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _enviandoManual ? null : _marcarManualmente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _enviandoManual
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : const Text('Confirmar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => setState(() => _marcandoManualmente = false), child: const Text('Cancelar')),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            Wrap(
              spacing: 8,
              children: List.generate(_filtros.length, (i) {
                final selected = _filtro == i;
                return ChoiceChip(
                  label: Text(_filtros[i]),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _filtro = i);
                    _carregar();
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textMuted, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 12.5),
                  side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                  backgroundColor: Colors.white,
                );
              }),
            ),
            const SizedBox(height: 16),
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
              ..._visiveis.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SolicitacaoCard(
                      solicitacao: s as Map<String, dynamic>,
                      tipo: EmpresaConfigScope.of(context).tipoFidelidade,
                      onAprovar: () => _resolver(s, 'aprovar'),
                      onRejeitar: () => _resolver(s, 'rejeitar'),
                    ),
                  )),
              if (_visiveis.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('Nenhuma solicitação encontrada.', style: TextStyle(color: AppColors.textMuted))),
                ),
            ],
            const SizedBox(height: 20),
            const WebFooter(),
          ],
        ),
      ),
    );
  }
}

class _SolicitacaoCard extends StatelessWidget {
  final Map<String, dynamic> solicitacao;
  final TipoFidelidade tipo;
  final VoidCallback onAprovar;
  final VoidCallback onRejeitar;

  const _SolicitacaoCard({required this.solicitacao, required this.tipo, required this.onAprovar, required this.onRejeitar});

  @override
  Widget build(BuildContext context) {
    final s = solicitacao;
    final cliente = s['cliente'] as Map<String, dynamic>;
    final nome = cliente['nome'] as String;
    final cpf = cliente['cpf'] as String;
    final cpfFormatado = '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    final unidade = tipo == TipoFidelidade.marcacoes ? '' : ' pts';
    final progresso = '${s['saldoAtual']}$unidade de ${s['metaFidelidade']}$unidade';
    final cupomFiscal = s['cupomFiscal'] as String?;
    final status = s['status'] as String;
    final dataSolicitacao = DateTime.parse(s['createdAt'] as String);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              nome.trim().isEmpty ? '?' : nome.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase(),
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text('CPF $cpfFormatado · $progresso', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  cupomFiscal != null ? 'Cupom fiscal: $cupomFiscal' : 'Sem cupom fiscal informado',
                  style: TextStyle(fontSize: 12, color: cupomFiscal != null ? AppColors.textMuted : AppColors.warning, fontStyle: cupomFiscal != null ? FontStyle.normal : FontStyle.italic),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_dataRelativa(dataSolicitacao), style: const TextStyle(fontSize: 11.5, color: AppColors.textHint)),
              const SizedBox(height: 8),
              if (status == 'PENDENTE')
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onRejeitar,
                      icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                      label: const Text('Rejeitar', style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onAprovar,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: status == 'APROVADA' ? AppColors.successBg : AppColors.dangerBg, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    status == 'APROVADA' ? 'Aprovada' : 'Rejeitada',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: status == 'APROVADA' ? AppColors.successText : AppColors.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _dataRelativa(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return 'Há ${diff.inDays}d';
  }
}
