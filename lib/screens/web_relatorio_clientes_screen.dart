import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

enum _ClientTier { gold, silver, bronze, starter }

class _Client {
  final String initials;
  final String name;
  final String email;
  final String city;
  final int stamps;
  final int spent;
  final String lastVisit;
  final _ClientTier tier;
  const _Client({
    required this.initials,
    required this.name,
    required this.email,
    required this.city,
    required this.stamps,
    required this.spent,
    required this.lastVisit,
    required this.tier,
  });
}

class WebRelatorioClientesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebRelatorioClientesScreen({super.key, required this.onSelect});

  @override
  State<WebRelatorioClientesScreen> createState() =>
      _WebRelatorioClientesScreenState();
}

class _WebRelatorioClientesScreenState
    extends State<WebRelatorioClientesScreen> {
  final _search = TextEditingController();
  int _filter = 0;
  static const _filters = [
    'Todos',
    'Ouro',
    'Prata',
    'Bronze',
    'Iniciante',
  ];

  final List<_Client> _clients = const [
    _Client(
      initials: 'RM',
      name: 'Ricardo Mendes',
      email: 'ricardo@email.com',
      city: 'São Paulo, SP',
      stamps: 248,
      spent: 1240,
      lastVisit: 'Há 2 dias',
      tier: _ClientTier.gold,
    ),
    _Client(
      initials: 'AS',
      name: 'Ana Souza',
      email: 'ana.souza@email.com',
      city: 'Rio de Janeiro, RJ',
      stamps: 156,
      spent: 780,
      lastVisit: 'Há 5 dias',
      tier: _ClientTier.silver,
    ),
    _Client(
      initials: 'FL',
      name: 'Felipe Lima',
      email: 'felipe.lima@email.com',
      city: 'Belo Horizonte, MG',
      stamps: 89,
      spent: 445,
      lastVisit: 'Há 1 semana',
      tier: _ClientTier.bronze,
    ),
    _Client(
      initials: 'MC',
      name: 'Mariana Costa',
      email: 'mariana.c@email.com',
      city: 'Curitiba, PR',
      stamps: 312,
      spent: 1560,
      lastVisit: 'Há 1 dia',
      tier: _ClientTier.gold,
    ),
    _Client(
      initials: 'JO',
      name: 'Juliana Oliveira',
      email: 'ju.oliveira@email.com',
      city: 'Porto Alegre, RS',
      stamps: 18,
      spent: 90,
      lastVisit: 'Há 3 semanas',
      tier: _ClientTier.starter,
    ),
    _Client(
      initials: 'PA',
      name: 'Pedro Almeida',
      email: 'pedro.almeida@email.com',
      city: 'Florianópolis, SC',
      stamps: 134,
      spent: 670,
      lastVisit: 'Há 2 semanas',
      tier: _ClientTier.silver,
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();
    return WebShell(
      current: AdminSection.relatorio,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebPageHeader(
              title: 'Relatório de Clientes',
              subtitle:
                  'Análise completa da base de clientes fidelizados do programa.',
              searchHint: 'Buscar por nome, e-mail ou cidade...',
              searchController: _search,
              primaryActionLabel: 'Exportar',
              primaryActionIcon: Icons.file_download_outlined,
              onPrimaryAction: () {},
            ),
            const SizedBox(height: 22),
            _buildKpiRow(),
            const SizedBox(height: 22),
            _buildFilterChips(),
            const SizedBox(height: 18),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _buildTableHeader(),
                  ...filtered.map(_buildRow),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  List<_Client> _filtered() {
    return _clients.where((c) {
      if (_filter == 1 && c.tier != _ClientTier.gold) return false;
      if (_filter == 2 && c.tier != _ClientTier.silver) return false;
      if (_filter == 3 && c.tier != _ClientTier.bronze) return false;
      if (_filter == 4 && c.tier != _ClientTier.starter) return false;
      final q = _search.text.toLowerCase();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.email.toLowerCase().contains(q) ||
          c.city.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildKpiRow() {
    final cards = [
      const _Kpi(
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
        label: 'TOTAL DE CLIENTES',
        value: '8.420',
        hint: '+12% no mês',
      ),
      const _Kpi(
        icon: Icons.workspace_premium,
        color: Color(0xFFD4A017),
        label: 'NÍVEL OURO',
        value: '1.842',
        hint: 'Top 22%',
      ),
      const _Kpi(
        icon: Icons.trending_up,
        color: AppColors.success,
        label: 'FATURAMENTO',
        value: 'R\$ 124.580',
        hint: 'Mês atual',
      ),
      const _Kpi(
        icon: Icons.redeem,
        color: AppColors.accent,
        label: 'RESGATES',
        value: '3.215',
        hint: 'Últimos 30 dias',
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 800;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i < cards.length - 1) const SizedBox(width: 14),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              cards[i],
              if (i < cards.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < _filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _filter = i),
              borderRadius: BorderRadius.circular(99),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _filter == i ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: _filter == i
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _filter == i
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 220,
            child: Text('CLIENTE', style: _headerStyle),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Text('LOCALIZAÇÃO', style: _headerStyle),
          ),
          SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text('SELOS', style: _headerStyle),
          ),
          SizedBox(
            width: 120,
            child: Text('GASTO TOTAL', style: _headerStyle),
          ),
          SizedBox(
            width: 110,
            child: Text('NÍVEL', style: _headerStyle),
          ),
          SizedBox(
            width: 110,
            child: Text('ÚLTIMA VISITA', style: _headerStyle),
          ),
          Expanded(
            child: Text(
              'AÇÕES',
              textAlign: TextAlign.right,
              style: _headerStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Client c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      c.initials,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        c.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    c.city,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '${c.stamps}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'R\$ ${c.spent}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.successText,
              ),
            ),
          ),
          SizedBox(width: 110, child: _TierChip(tier: c.tier)),
          SizedBox(
            width: 110,
            child: Text(
              c.lastVisit,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _IconAction(
                  icon: Icons.visibility_outlined,
                  color: AppColors.primary,
                  tooltip: 'Ver perfil',
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.message_outlined,
                  color: AppColors.success,
                  tooltip: 'Enviar mensagem',
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.more_horiz,
                  color: AppColors.textMuted,
                  tooltip: 'Mais',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mostrando 6 de 8.420 clientes',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Row(
          children: [
            _PageButton(icon: Icons.chevron_left, onTap: () {}),
            _PageButton(label: '1', selected: true, onTap: () {}),
            _PageButton(label: '2', onTap: () {}),
            _PageButton(label: '3', onTap: () {}),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '...',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            _PageButton(label: '1403', onTap: () {}),
            _PageButton(icon: Icons.chevron_right, onTap: () {}),
          ],
        ),
      ],
    );
  }
}

const _headerStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w800,
  color: AppColors.textMuted,
  letterSpacing: 0.7,
);

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

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String hint;
  const _Kpi({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.hint,
  });

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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final _ClientTier tier;
  const _TierChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final IconData icon;
    late final Color color;
    late final Color bg;
    switch (tier) {
      case _ClientTier.gold:
        label = 'Ouro';
        icon = Icons.workspace_premium;
        color = const Color(0xFF8B6914);
        bg = const Color(0xFFFFF6D6);
        break;
      case _ClientTier.silver:
        label = 'Prata';
        icon = Icons.workspace_premium_outlined;
        color = const Color(0xFF455A64);
        bg = const Color(0xFFE7ECEF);
        break;
      case _ClientTier.bronze:
        label = 'Bronze';
        icon = Icons.military_tech_outlined;
        color = const Color(0xFF6D4C41);
        bg = const Color(0xFFF1E2D2);
        break;
      case _ClientTier.starter:
        label = 'Iniciante';
        icon = Icons.emoji_events_outlined;
        color = const Color(0xFF5B0A8F);
        bg = const Color(0xFFEFE5F8);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: color, size: 16),
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: icon != null
                ? Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.textDark,
                  )
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textDark,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
