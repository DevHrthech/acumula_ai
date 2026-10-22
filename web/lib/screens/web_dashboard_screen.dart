import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../widgets/web_sidebar.dart';

class WebDashboardScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebDashboardScreen({super.key, required this.onSelect});

  @override
  State<WebDashboardScreen> createState() => _WebDashboardScreenState();
}

class _WebDashboardScreenState extends State<WebDashboardScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _dados;

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
      final dados = await session.api.dashboard();
      if (!mounted) return;
      setState(() => _dados = dados);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar o dashboard.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.dashboard,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebPageHeader(
              title: 'Dashboard Principal',
              subtitle: 'Visão geral do desempenho de fidelidade e campanhas ativas.',
            ),
            const SizedBox(height: 28),
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
              _buildKpiRow(_dados!),
              const SizedBox(height: 20),
              _buildActivityTable(_dados!['atividadesRecentes'] as List<dynamic>),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> dados) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        final cards = [
          _KpiCard(
            icon: Icons.people_alt_outlined,
            label: 'CLIENTES VINCULADOS',
            value: '${dados['clientesAtivos']}',
          ),
          _KpiCard(
            icon: Icons.campaign_outlined,
            label: 'CAMPANHAS ATIVAS',
            value: '${dados['campanhasAtivas']}',
            isAccent: true,
          ),
          _KpiCard(
            icon: Icons.check_circle_outline,
            label: 'MARCAÇÕES NO MÊS',
            value: '${dados['marcacoesMes']}',
          ),
          _KpiCard(
            icon: Icons.card_giftcard_outlined,
            label: 'RESGATES NO MÊS',
            value: '${dados['resgatesMes']}',
          ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _buildActivityTable(List<dynamic> atividades) {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                Text(
                  'Atividades Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                _Cell('Cliente', isHeader: true, flex: 2),
                _Cell('Ação', isHeader: true, flex: 2),
                _Cell('Data', isHeader: true, flex: 1),
                _Cell('Valor', isHeader: true, flex: 1),
              ],
            ),
          ),
          if (atividades.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhuma atividade ainda.', style: TextStyle(color: AppColors.textMuted)),
            ),
          ...atividades.map((a) {
            final tipo = a['tipo'] as String;
            final nome = a['cliente'] as String;
            final data = DateTime.parse(a['dataHora'] as String);
            final acao = tipo == 'MARCACAO' ? 'Nova marcação' : 'Resgate de recompensa';
            final valor = tipo == 'MARCACAO'
                ? (a['pontosGerados'] != null ? '+${a['pontosGerados']} pts' : '+1')
                : '-${a['saldoDescontado']}';
            final initials = nome.trim().isEmpty
                ? '?'
                : nome.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase();
            return Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  _ClientCell(initials: initials, name: nome, flex: 2),
                  _Cell(acao, flex: 2),
                  _Cell(_dataRelativa(data), flex: 1, color: AppColors.textMuted),
                  _Cell(valor, flex: 1, fontWeight: FontWeight.w600),
                ],
              ),
            );
          }),
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isAccent;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isAccent
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            )
          : _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isAccent ? Colors.white.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isAccent ? Colors.white : AppColors.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isAccent ? Colors.white70 : AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isAccent ? Colors.white : AppColors.textDark,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final int flex;
  final Color? color;
  final FontWeight? fontWeight;
  const _Cell(
    this.text, {
    this.isHeader = false,
    required this.flex,
    this.color,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 11 : 13,
          fontWeight: fontWeight ?? (isHeader ? FontWeight.w700 : FontWeight.w500),
          color: color ?? (isHeader ? AppColors.textMuted : AppColors.textDark),
          letterSpacing: isHeader ? 0.6 : 0,
        ),
      ),
    );
  }
}

class _ClientCell extends StatelessWidget {
  final String initials;
  final String name;
  final int flex;
  const _ClientCell({
    required this.initials,
    required this.name,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.1)),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
