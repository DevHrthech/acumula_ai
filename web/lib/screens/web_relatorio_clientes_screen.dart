import 'package:flutter/material.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

class WebRelatorioClientesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebRelatorioClientesScreen({super.key, required this.onSelect});

  @override
  State<WebRelatorioClientesScreen> createState() => _WebRelatorioClientesScreenState();
}

class _WebRelatorioClientesScreenState extends State<WebRelatorioClientesScreen> {
  final _search = TextEditingController();
  bool _carregando = true;
  String? _erro;
  List<dynamic> _clientes = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _carregar();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      final clientes = await session.api.listarClientes();
      if (!mounted) return;
      setState(() => _clientes = clientes);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar o relatório.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<dynamic> get _filtrados {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _clientes;
    return _clientes.where((c) {
      final nome = (c['nome'] as String).toLowerCase();
      final email = (c['email'] as String? ?? '').toLowerCase();
      final cpf = c['cpf'] as String;
      return nome.contains(q) || email.contains(q) || cpf.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.relatorio,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebPageHeader(
              title: 'Relatório de Clientes',
              subtitle: 'Todos os clientes vinculados ao seu programa de fidelidade.',
              searchHint: 'Buscar por nome, e-mail ou CPF...',
              searchController: _search,
            ),
            const SizedBox(height: 22),
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
              _buildKpiRow(),
              const SizedBox(height: 22),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    if (_filtrados.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum cliente encontrado.', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ..._filtrados.map((c) => _buildRow(c as Map<String, dynamic>)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    final totalMarcacoes = _clientes.fold<int>(0, (acc, c) => acc + (c['totalMarcacoes'] as int));
    final totalResgates = _clientes.fold<int>(0, (acc, c) => acc + (c['totalResgates'] as int));
    final cards = [
      _Kpi(icon: Icons.people_alt_outlined, color: AppColors.primary, label: 'TOTAL DE CLIENTES', value: '${_clientes.length}'),
      _Kpi(icon: Icons.check_circle_outline, color: AppColors.success, label: 'MARCAÇÕES REGISTRADAS', value: '$totalMarcacoes'),
      _Kpi(icon: Icons.redeem, color: AppColors.accent, label: 'RESGATES REALIZADOS', value: '$totalResgates'),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 700;
        if (wide) {
          return Row(children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 14),
            ],
          ]);
        }
        return Column(children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 12),
          ],
        ]);
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: const Row(
        children: [
          SizedBox(width: 220, child: Text('CLIENTE', style: _headerStyle)),
          SizedBox(width: 130, child: Text('CPF', style: _headerStyle)),
          SizedBox(width: 100, child: Text('SALDO ATUAL', style: _headerStyle)),
          SizedBox(width: 110, child: Text('MARCAÇÕES', style: _headerStyle)),
          SizedBox(width: 100, child: Text('RESGATES', style: _headerStyle)),
          Expanded(child: Text('CLIENTE DESDE', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> c) {
    final nome = c['nome'] as String;
    final initials = nome.trim().isEmpty ? '?' : nome.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
    final dataVinculo = DateTime.parse(c['dataVinculo'] as String);
    final dataStr = '${dataVinculo.day.toString().padLeft(2, '0')}/${dataVinculo.month.toString().padLeft(2, '0')}/${dataVinculo.year}';
    final cpf = c['cpf'] as String;
    final cpfFormatado = '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Center(child: Text(initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nome, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text((c['email'] as String?) ?? c['telefone'] as String, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 130, child: Text(cpfFormatado, style: const TextStyle(fontSize: 12.5, color: AppColors.textDark))),
          SizedBox(width: 100, child: Text('${c['saldoAtual']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          SizedBox(width: 110, child: Text('${c['totalMarcacoes']}', style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
          SizedBox(width: 100, child: Text('${c['totalResgates']}', style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
          Expanded(child: Text(dataStr, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.7);

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Kpi({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.7)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark, height: 1.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
