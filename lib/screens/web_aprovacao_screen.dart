import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

enum _ApprovalStatus { pending, approved, rejected }

class _ApprovalItem {
  final String id;
  final String initials;
  final String name;
  final String action;
  final String detail;
  final String date;
  _ApprovalStatus status;
  _ApprovalItem({
    required this.id,
    required this.initials,
    required this.name,
    required this.action,
    required this.detail,
    required this.date,
    this.status = _ApprovalStatus.pending,
  });
}

class WebAprovacaoScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebAprovacaoScreen({super.key, required this.onSelect});

  @override
  State<WebAprovacaoScreen> createState() => _WebAprovacaoScreenState();
}

class _WebAprovacaoScreenState extends State<WebAprovacaoScreen> {
  final _search = TextEditingController();
  int _filter = 0;
  static const _filters = ['Todas', 'Pendentes', 'Aprovadas', 'Rejeitadas'];

  final List<_ApprovalItem> _items = [
    _ApprovalItem(
      id: '1',
      initials: 'AC',
      name: 'Café do Ponto',
      action: 'Nova campanha: 10 Cafés = 1 Grátis',
      detail: 'Loja: Centro • Validade: 30 dias',
      date: 'Há 12 min',
      status: _ApprovalStatus.pending,
    ),
    _ApprovalItem(
      id: '2',
      initials: 'SE',
      name: 'Studio Estrela',
      action: 'Promoção: 20% OFF Cortes',
      detail: 'Loja: Jardins • Validade: 7 dias',
      date: 'Há 45 min',
      status: _ApprovalStatus.pending,
    ),
    _ApprovalItem(
      id: '3',
      initials: 'PB',
      name: 'Padoca do Bairro',
      action: 'Pontos em dobro na quarta',
      detail: 'Loja: Vila Madalena • Permanente',
      date: 'Há 2 horas',
      status: _ApprovalStatus.pending,
    ),
    _ApprovalItem(
      id: '4',
      initials: 'GA',
      name: 'Grão & Arte',
      action: 'Compre 1, leve 2 em bolos',
      detail: 'Loja: Pinheiros • Validade: 14 dias',
      date: 'Há 3 horas',
      status: _ApprovalStatus.pending,
    ),
    _ApprovalItem(
      id: '5',
      initials: 'AC',
      name: 'Café do Ponto',
      action: 'Promoção: Cappuccino 2x1',
      detail: 'Loja: Centro • Validade: 5 dias',
      date: 'Há 5 horas',
      status: _ApprovalStatus.pending,
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();
    return WebShell(
      current: AdminSection.aprovacao,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WebPageHeader(
              title: 'Aprovação de Campanhas',
              subtitle: 'Revise e aprove as campanhas enviadas pelos lojistas.',
              searchHint: 'Buscar por loja ou campanha...',
              searchController: _search,
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
          ],
        ),
      ),
    );
  }

  List<_ApprovalItem> _filteredItems() {
    final filterIdx = _filter;
    return _items.where((i) {
      if (filterIdx == 1 && i.status != _ApprovalStatus.pending) return false;
      if (filterIdx == 2 && i.status != _ApprovalStatus.approved) return false;
      if (filterIdx == 3 && i.status != _ApprovalStatus.rejected) return false;
      final q = _search.text.toLowerCase();
      if (q.isEmpty) return true;
      return i.name.toLowerCase().contains(q) ||
          i.action.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildKpiRow() {
    final pending = _items
        .where((i) => i.status == _ApprovalStatus.pending)
        .length;
    final approved = _items
        .where((i) => i.status == _ApprovalStatus.approved)
        .length;
    final rejected = _items
        .where((i) => i.status == _ApprovalStatus.rejected)
        .length;
    final cards = [
      _Kpi(
        icon: Icons.inbox_outlined,
        color: AppColors.primary,
        label: 'TOTAL NA FILA',
        value: '${_items.length}',
        hint: 'Campanhas aguardando revisão',
      ),
      _Kpi(
        icon: Icons.access_time,
        color: AppColors.warning,
        label: 'PENDENTES',
        value: '$pending',
        hint: 'Requerem ação',
      ),
      _Kpi(
        icon: Icons.check_circle_outline,
        color: AppColors.success,
        label: 'APROVADAS HOJE',
        value: '$approved',
        hint: 'Disponíveis no app',
      ),
      _Kpi(
        icon: Icons.cancel_outlined,
        color: AppColors.danger,
        label: 'REJEITADAS',
        value: '$rejected',
        hint: 'Não publicadas',
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
            width: 260,
            child: Text(
              'LOJA / CAMPANHA',
              style: _headerStyle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('DETALHES', style: _headerStyle),
          ),
          SizedBox(
            width: 100,
            child: Text('DATA', style: _headerStyle),
          ),
          SizedBox(
            width: 110,
            child: Text('STATUS', style: _headerStyle),
          ),
          SizedBox(
            width: 130,
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

  Widget _buildRow(_ApprovalItem i) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      i.initials,
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
                        i.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i.action,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
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
          Expanded(
            child: Text(
              i.detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              i.date,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 110, child: _StatusChip(status: i.status)),
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _IconAction(
                  icon: Icons.check,
                  color: AppColors.success,
                  tooltip: 'Aprovar',
                  onTap: () => setState(
                    () => i.status = _ApprovalStatus.approved,
                  ),
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.close,
                  color: AppColors.danger,
                  tooltip: 'Rejeitar',
                  onTap: () => setState(
                    () => i.status = _ApprovalStatus.rejected,
                  ),
                ),
                const SizedBox(width: 6),
                _IconAction(
                  icon: Icons.visibility_outlined,
                  color: AppColors.primary,
                  tooltip: 'Detalhes',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
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
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _ApprovalStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (status) {
      case _ApprovalStatus.pending:
        label = 'Pendente';
        bg = AppColors.warningBg;
        fg = AppColors.warningText;
        break;
      case _ApprovalStatus.approved:
        label = 'Aprovada';
        bg = AppColors.successBg;
        fg = AppColors.successText;
        break;
      case _ApprovalStatus.rejected:
        label = 'Rejeitada';
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
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
