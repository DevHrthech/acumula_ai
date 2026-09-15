import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

/// Painel administrativo (web) — listagem e gestão das campanhas de
/// fidelidade cadastradas. O botão "Nova Campanha" abre o formulário
/// já existente em [AdminSection.cadastro].
class WebCampanhasScreen extends StatelessWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebCampanhasScreen({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.campanhas,
      onSelect: onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBreadcrumb(),
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 26),
            _buildKpiRow(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildTable(),
            const SizedBox(height: 16),
            _buildPagination(),
            const SizedBox(height: 22),
            _buildTipBanner(),
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
        Text(
          'Painel',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.textHint,
        ),
        const Text(
          'Campanhas Criadas',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
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
            const Text(
              'Campanhas de Fidelidade',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gerencie todas as campanhas ativas, pausadas e encerradas da sua loja.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
          ],
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Exportar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => onSelect(AdminSection.cadastro),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Campanha'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 16),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildKpiRow() {
    final cards = [
      _StatCard(
        icon: Icons.campaign_outlined,
        iconBg: const Color(0xFFE9D5F5),
        iconColor: AppColors.primary,
        label: 'CAMPANHAS ATIVAS',
        value: '4',
        badgeText: 'Em Operação',
        badgeColor: AppColors.success,
        badgeBg: AppColors.successBg,
        caption: 'Total cadastrado: 12 campanhas',
        barColor: AppColors.primary,
        barFill: 0.9,
      ),
      _StatCard(
        icon: Icons.card_giftcard_outlined,
        iconBg: const Color(0xFFFFF6E5),
        iconColor: AppColors.accent,
        label: 'TOTAL DE RESGATES',
        value: '1.840',
        trendText: '+18%',
        caption: 'Comparado aos últimos 30 dias',
        barColor: AppColors.accent,
        barFill: 0.55,
      ),
      _StatCard(
        icon: Icons.groups_outlined,
        iconBg: const Color(0xFFE9D5F5),
        iconColor: AppColors.primary,
        label: 'CLIENTES ENGAJADOS',
        value: '3.420',
        avatarStack: true,
        caption: 'Acumulando selos e pontos hoje',
        barColor: AppColors.primary,
        barFill: 0.9,
      ),
      _StatCard(
        icon: Icons.pie_chart_outline_rounded,
        iconBg: const Color(0xFFFFF6E5),
        iconColor: AppColors.accent,
        label: 'TAXA MÉDIA DE CONCLUSÃO',
        value: '68%',
        caption: 'De cartelas completadas com sucesso',
        barColor: AppColors.accent,
        barFill: 0.9,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
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
        final perRow = c.maxWidth > 560 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards)
              SizedBox(
                width: (c.maxWidth - (perRow - 1) * 16) / perRow,
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 820;
        final search = TextField(
          decoration: InputDecoration(
            hintText: 'Buscar campanha por nome ou prêmio...',
            hintStyle: const TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textHint,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        );
        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DropdownPill(label: 'Todos os Status'),
            const SizedBox(width: 10),
            _DropdownPill(label: 'Tipo: Todos'),
            const SizedBox(width: 10),
            _DropdownPill(
              label: 'Mais Recentes',
              icon: Icons.swap_vert_rounded,
            ),
            const SizedBox(width: 10),
            _ViewToggle(),
          ],
        );
        if (wide) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 12),
              controls,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            search,
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: controls,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, c) {
        // Um SingleChildScrollView horizontal entrega largura NÃO limitada ao
        // filho; um SizedBox com largura fixa é o que dá às linhas (que usam
        // Expanded/flex) uma largura finita para se basearem.
        final tableWidth = c.maxWidth > 920 ? c.maxWidth : 920.0;
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: const Row(
                      children: [
                        _HeaderCell('CAMPANHA & PRÊMIO', flex: 3),
                        _HeaderCell('REGRA & MECÂNICA', flex: 2),
                        _HeaderCell('PERÍODO DE VALIDADE', flex: 2),
                        _HeaderCell('ADESÃO & RESGATES', flex: 2),
                        _HeaderCell('STATUS', flex: 1),
                        _HeaderCell('AÇÕES', flex: 1),
                      ],
                    ),
                  ),
                  for (final item in _campanhas) _CampanhaRow(item: item),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mostrando 5 de 12 campanhas cadastradas',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Row(
          children: [
            _PageArrow(icon: Icons.chevron_left),
            const SizedBox(width: 6),
            _PageNumber(label: '1', selected: true),
            const SizedBox(width: 6),
            _PageNumber(label: '2'),
            const SizedBox(width: 6),
            _PageNumber(label: '3'),
            const SizedBox(width: 6),
            _PageArrow(icon: Icons.chevron_right),
          ],
        ),
      ],
    );
  }

  Widget _buildTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dica de Engajamento para Lojistas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Campanhas com metas menores de 5 a 8 compras possuem taxa de conversão 34% mais alta no primeiro mês.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Ver melhores práticas'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBg;
  final String? trendText;
  final bool avatarStack;
  final String caption;
  final Color barColor;
  final double barFill;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.badgeText,
    this.badgeColor,
    this.badgeBg,
    this.trendText,
    this.avatarStack = false,
    required this.caption,
    required this.barColor,
    required this.barFill,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: _cardDecoration(),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (badgeText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: badgeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                badgeText!,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (trendText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                size: 12,
                                color: AppColors.successText,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                trendText!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (avatarStack) const _AvatarStack(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: AppColors.border.withValues(alpha: 0.4)),
                    FractionallySizedBox(
                      widthFactor: barFill.clamp(0, 1),
                      alignment: Alignment.centerLeft,
                      child: Container(color: barColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    Widget avatar(String initials, Color color) => Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
    return SizedBox(
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar('JS', AppColors.primary),
          Positioned(left: 14, child: avatar('MI', AppColors.primaryDark)),
          Positioned(
            left: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: const Text(
                '+99',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _DropdownPill({required this.label, this.icon = Icons.expand_more});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.view_list_rounded,
              size: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 2),
          const Padding(
            padding: EdgeInsets.all(7),
            child: Icon(
              Icons.grid_view_rounded,
              size: 17,
              color: AppColors.textMuted,
            ),
          ),
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
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  final IconData icon;
  const _PageArrow({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 18, color: AppColors.textMuted),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final String label;
  final bool selected;
  const _PageNumber({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
    );
  }
}

enum _Status { ativa, encerrada, pausada, rascunho }

class _RowAction {
  final IconData icon;
  final Color color;
  final Color bg;
  const _RowAction({required this.icon, required this.color, required this.bg});
}

class _CampanhaItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? tag;
  final String nome;
  final String premio;
  final IconData regraIcon;
  final String regraTitulo;
  final String regraSub;
  final IconData periodoIcon;
  final Color periodoIconColor;
  final String periodoLinha1;
  final String periodoLinha2;
  final String clientesLabel;
  final String resgatesLabel;
  final double progress;
  final _Status status;
  final List<_RowAction> actions;

  const _CampanhaItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.tag,
    required this.nome,
    required this.premio,
    required this.regraIcon,
    required this.regraTitulo,
    required this.regraSub,
    required this.periodoIcon,
    required this.periodoIconColor,
    required this.periodoLinha1,
    required this.periodoLinha2,
    required this.clientesLabel,
    required this.resgatesLabel,
    required this.progress,
    required this.status,
    required this.actions,
  });
}

final List<_CampanhaItem> _campanhas = [
  _CampanhaItem(
    icon: Icons.local_cafe_outlined,
    iconBg: const Color(0xFFE9D5F5),
    iconColor: AppColors.primary,
    tag: 'Destaque',
    nome: 'Verão Premiado 2024',
    premio: 'Prêmio: 1 Café Expresso Grande ou 15% OFF',
    regraIcon: Icons.card_giftcard,
    regraTitulo: '10 Compras',
    regraSub: 'Cartela de Selos',
    periodoIcon: Icons.schedule,
    periodoIconColor: AppColors.warning,
    periodoLinha1: '01/Jan a 28/Fev/2024',
    periodoLinha2: 'Restam 18 dias',
    clientesLabel: '428 clientes',
    resgatesLabel: '84 resgates',
    progress: 0.4,
    status: _Status.ativa,
    actions: [
      _RowAction(icon: Icons.edit_outlined, color: AppColors.primary, bg: AppColors.primary.withValues(alpha: 0.08)),
      _RowAction(icon: Icons.pause_rounded, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.more_vert, color: AppColors.textMuted, bg: AppColors.surface),
    ],
  ),
  _CampanhaItem(
    icon: Icons.star_outline_rounded,
    iconBg: const Color(0xFFFFF6E5),
    iconColor: AppColors.accent,
    nome: 'Fidelidade Café Especial',
    premio: 'Prêmio: Copo Térmico Exclusivo',
    regraIcon: Icons.paid_outlined,
    regraTitulo: '100 Pontos',
    regraSub: 'Acúmulo Monetário',
    periodoIcon: Icons.all_inclusive,
    periodoIconColor: AppColors.textMuted,
    periodoLinha1: 'Permanente',
    periodoLinha2: 'Sem data limite',
    clientesLabel: '1.250 clientes',
    resgatesLabel: '312 resgates',
    progress: 0.65,
    status: _Status.ativa,
    actions: [
      _RowAction(icon: Icons.edit_outlined, color: AppColors.primary, bg: AppColors.primary.withValues(alpha: 0.08)),
      _RowAction(icon: Icons.pause_rounded, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.more_vert, color: AppColors.textMuted, bg: AppColors.surface),
    ],
  ),
  _CampanhaItem(
    icon: Icons.cake_outlined,
    iconBg: const Color(0xFFFCE7F3),
    iconColor: const Color(0xFFC2185B),
    nome: 'Festival de Sobremesas',
    premio: 'Prêmio: Torta Doce Artesanal Grátis',
    regraIcon: Icons.card_giftcard,
    regraTitulo: '5 Compras',
    regraSub: 'Cartela de Selos',
    periodoIcon: Icons.event_busy_outlined,
    periodoIconColor: AppColors.textMuted,
    periodoLinha1: '15/Nov a 31/Dez/2023',
    periodoLinha2: 'Encerrada',
    clientesLabel: '890 clientes',
    resgatesLabel: '450 resgates',
    progress: 1,
    status: _Status.encerrada,
    actions: [
      _RowAction(icon: Icons.bar_chart_rounded, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.restore_rounded, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.more_vert, color: AppColors.textMuted, bg: AppColors.surface),
    ],
  ),
  _CampanhaItem(
    icon: Icons.sports_bar_outlined,
    iconBg: const Color(0xFFFFF6E5),
    iconColor: AppColors.accent,
    nome: 'Happy Hour em Dobro',
    premio: 'Prêmio: Chopp Artesanal 500ml',
    regraIcon: Icons.replay_circle_filled_outlined,
    regraTitulo: '50 Pontos',
    regraSub: 'Pontos Recorrentes',
    periodoIcon: Icons.pause_circle_outline,
    periodoIconColor: AppColors.warning,
    periodoLinha1: 'Sextas e Sábados',
    periodoLinha2: 'Temporariamente em pausa',
    clientesLabel: '310 clientes',
    resgatesLabel: '95 resgates',
    progress: 0.3,
    status: _Status.pausada,
    actions: [
      _RowAction(icon: Icons.play_arrow_rounded, color: AppColors.primary, bg: AppColors.primary.withValues(alpha: 0.08)),
      _RowAction(icon: Icons.edit_outlined, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.more_vert, color: AppColors.textMuted, bg: AppColors.surface),
    ],
  ),
  _CampanhaItem(
    icon: Icons.restaurant_outlined,
    iconBg: const Color(0xFFE3F2FD),
    iconColor: AppColors.warning,
    nome: 'Combo Almoço Executivo',
    premio: 'Prêmio: 1 Almoço Cortesia',
    regraIcon: Icons.card_giftcard,
    regraTitulo: '8 Compras',
    regraSub: 'Configuração Pendente',
    periodoIcon: Icons.edit_note_outlined,
    periodoIconColor: AppColors.textMuted,
    periodoLinha1: 'Não definido',
    periodoLinha2: 'Fase de Rascunho',
    clientesLabel: '0 participantes',
    resgatesLabel: '0 resgates',
    progress: 0,
    status: _Status.rascunho,
    actions: [
      _RowAction(icon: Icons.publish_outlined, color: AppColors.primary, bg: AppColors.primary.withValues(alpha: 0.08)),
      _RowAction(icon: Icons.edit_outlined, color: AppColors.textMuted, bg: AppColors.surface),
      _RowAction(icon: Icons.delete_outline, color: AppColors.danger, bg: AppColors.dangerBg),
    ],
  ),
];

class _CampanhaRow extends StatelessWidget {
  final _CampanhaItem item;
  const _CampanhaRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFF2))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.nome,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (item.tag != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                item.tag!,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.premio,
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
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.regraIcon, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      item.regraTitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.regraSub,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.periodoLinha1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      item.periodoIcon,
                      size: 13,
                      color: item.periodoIconColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.periodoLinha2,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.periodoIconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.clientesLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Text(
                        '  •  ',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                      Text(
                        item.resgatesLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.status == _Status.encerrada
                            ? AppColors.textHint
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _StatusChip(status: item.status),
          ),
          Expanded(
            flex: 1,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final action in item.actions)
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: action.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, size: 16, color: action.color),
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
  final _Status status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _Status.ativa:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Ativa',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        );
      case _Status.encerrada:
        return _pill('Encerrada', AppColors.surface, AppColors.textMuted);
      case _Status.pausada:
        return _pill('Pausada', const Color(0xFFFFF1D6), const Color(0xFF9A6A00));
      case _Status.rascunho:
        return _pill('Rascunho', AppColors.warningBg, AppColors.warningText);
    }
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: bg == AppColors.surface
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
