import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

/// Painel administrativo (web) — acompanhamento das promoções/postagens
/// anunciadas no feed do app. O botão "Nova Promoção" abre o formulário
/// já existente em [AdminSection.postar].
class WebPromocoesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebPromocoesScreen({super.key, required this.onSelect});

  @override
  State<WebPromocoesScreen> createState() => _WebPromocoesScreenState();
}

class _WebPromocoesScreenState extends State<WebPromocoesScreen> {
  _Filter _filter = _Filter.todas;

  List<_PromoPost> get _filtered {
    switch (_filter) {
      case _Filter.todas:
        return _promos;
      case _Filter.ativas:
        return _promos.where((p) => p.status == _PromoStatus.ativa).toList();
      case _Filter.agendadas:
        return _promos.where((p) => p.status == _PromoStatus.agendada).toList();
      case _Filter.expiradas:
        return _promos.where((p) => p.status == _PromoStatus.expirada).toList();
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
            _buildKpiRow(),
            const SizedBox(height: 20),
            _buildTipBanner(),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 18),
            for (final promo in _filtered) ...[
              _PromoCard(promo: promo),
              const SizedBox(height: 18),
            ],
            _buildPagination(),
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
      children: const [
        Icon(Icons.campaign, size: 15, color: AppColors.primary),
        SizedBox(width: 6),
        Text(
          'GESTÃO DE ENGAJAMENTO',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 0.8,
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
              'Promoções Anunciadas',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Acompanhe as postagens, ofertas relâmpago e comunicados '
              'enviados para o feed dos seus clientes.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              action,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [title, const SizedBox(height: 16), action],
        );
      },
    );
  }

  Widget _buildKpiRow() {
    final cards = [
      _StatCard(
        icon: Icons.dynamic_feed_outlined,
        iconBg: const Color(0xFFE9D5F5),
        iconColor: AppColors.primary,
        label: 'TOTAL DE POSTAGENS',
        value: '28',
        valueSuffix: 'publicadas',
        caption: 'Histórico acumulado',
      ),
      _StatCard(
        icon: Icons.visibility_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: AppColors.warning,
        label: 'VISUALIZAÇÕES NO APP',
        value: '18.450',
        trendText: '+24%',
        caption: 'Impacto total nos feeds nesta semana',
      ),
      _StatCard(
        icon: Icons.touch_app_outlined,
        iconBg: const Color(0xFFFCE7F3),
        iconColor: const Color(0xFFC2185B),
        label: 'CLIQUES / ENGAJAMENTO',
        value: '2.840',
        badgeText: '15.4% taxa',
        badgeBg: AppColors.textDark,
        badgeFg: Colors.white,
        caption: 'Interações diretas com as ofertas',
      ),
      _StatCard(
        icon: Icons.bolt_rounded,
        iconBg: Colors.white,
        iconColor: AppColors.accent,
        label: 'PROMOÇÕES ATIVAS HOJE',
        value: '3',
        valueSuffix: 'ofertas no ar',
        caption: 'Transmitindo aos clientes',
        highlighted: true,
        pulsing: true,
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Row(
                  children: [
                    const Text(
                      'Dica de Engajamento Inteligente',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'IA ACUMULA',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    children: [
                      TextSpan(text: 'Postagens com fotos reais de produtos e chamadas como '),
                      TextSpan(
                        text: '"Pontos em Dobro"',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      TextSpan(text: ' geram '),
                      TextSpan(
                        text: '38% mais visitas',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success),
                      ),
                      TextSpan(text: ' presenciais às lojas parceiras.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Criar com IA'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 820;
        final tabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterTab(
                label: 'Todas (28)',
                selected: _filter == _Filter.todas,
                onTap: () => setState(() => _filter = _Filter.todas),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Ativas no Feed (3)',
                dotColor: AppColors.success,
                selected: _filter == _Filter.ativas,
                onTap: () => setState(() => _filter = _Filter.ativas),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Agendadas (2)',
                dotColor: AppColors.primary,
                selected: _filter == _Filter.agendadas,
                onTap: () => setState(() => _filter = _Filter.agendadas),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Expiradas (23)',
                selected: _filter == _Filter.expiradas,
                onTap: () => setState(() => _filter = _Filter.expiradas),
              ),
            ],
          ),
        );
        final search = SizedBox(
          width: wide ? 260 : double.infinity,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por mensagem ou palavra...',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
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
          ),
        );
        final period = _DropdownPill(label: 'Últimos 30 dias', icon: Icons.expand_more);
        if (wide) {
          return Row(
            children: [
              Expanded(child: tabs),
              const SizedBox(width: 12),
              search,
              const SizedBox(width: 10),
              period,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tabs,
            const SizedBox(height: 12),
            search,
            const SizedBox(height: 10),
            period,
          ],
        );
      },
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Mostrando 1 a 4 de 28 promoções',
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Text('…', style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(width: 6),
            _PageNumber(label: '7'),
            const SizedBox(width: 6),
            _PageArrow(icon: Icons.chevron_right),
          ],
        ),
      ],
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
  final String? valueSuffix;
  final String? trendText;
  final String? badgeText;
  final Color? badgeBg;
  final Color? badgeFg;
  final String caption;
  final bool highlighted;
  final bool pulsing;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueSuffix,
    this.trendText,
    this.badgeText,
    this.badgeBg,
    this.badgeFg,
    required this.caption,
    this.highlighted = false,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = highlighted ? AppColors.textDark.withValues(alpha: 0.7) : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: highlighted
          ? BoxDecoration(
              color: const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            )
          : _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: highlighted ? Border.all(color: AppColors.accent.withValues(alpha: 0.4)) : null,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: 6),
                Text(
                  valueSuffix!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(width: 8),
              if (trendText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_upward, size: 11, color: AppColors.successText),
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
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: badgeFg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (pulsing) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  caption,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
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
          Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

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
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
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
        border: Border.all(color: selected ? AppColors.primary : AppColors.border),
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

enum _Filter { todas, ativas, agendadas, expiradas }

enum _PromoStatus { ativa, agendada, expirada }

class _PromoAction {
  final IconData icon;
  final String label;
  final bool primary;
  final bool danger;
  const _PromoAction({
    required this.icon,
    required this.label,
    this.primary = false,
    this.danger = false,
  });
}

class _PromoPost {
  final IconData imageIcon;
  final List<Color> imageGradient;
  final String pointsBadge;
  final _PromoStatus status;
  final String statusLabel;
  final Color statusColor;
  final String timeLabel;
  final String audienceLabel;
  final IconData audienceIcon;
  final Color? audienceColor;
  final String message;
  final String? infoNote;
  final List<_Stat> stats;
  final List<_PromoAction> actions;

  const _PromoPost({
    required this.imageIcon,
    required this.imageGradient,
    required this.pointsBadge,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.timeLabel,
    required this.audienceLabel,
    required this.audienceIcon,
    this.audienceColor,
    required this.message,
    this.infoNote,
    required this.stats,
    required this.actions,
  });
}

class _Stat {
  final IconData icon;
  final String value;
  final String label;
  const _Stat(this.icon, this.value, this.label);
}

final List<_PromoPost> _promos = [
  _PromoPost(
    imageIcon: Icons.local_cafe,
    imageGradient: const [Color(0xFF8D6E63), Color(0xFF5D4037)],
    pointsBadge: '2x Pontos',
    status: _PromoStatus.ativa,
    statusLabel: 'No Feed do App',
    statusColor: AppColors.success,
    timeLabel: 'Hoje às 08:30 (por Admin)',
    audienceLabel: 'Todos os Clientes',
    audienceIcon: Icons.groups_outlined,
    message: 'Comece seu dia com energia extra! Peça qualquer café especial '
        'e ganhe o dobro de pontos em sua conta fidelidade.',
    stats: [
      _Stat(Icons.visibility_outlined, '1.420', 'visualizações'),
      _Stat(Icons.touch_app_outlined, '185', 'cliques'),
      _Stat(Icons.share_outlined, '34', 'compartilhamentos'),
    ],
    actions: [
      _PromoAction(icon: Icons.phone_iphone, label: 'Ver no App'),
      _PromoAction(icon: Icons.edit_outlined, label: 'Editar'),
      _PromoAction(icon: Icons.content_copy_outlined, label: 'Duplicar'),
      _PromoAction(icon: Icons.block, label: '', danger: true),
    ],
  ),
  _PromoPost(
    imageIcon: Icons.checkroom,
    imageGradient: const [Color(0xFFD7A86E), Color(0xFFB08655)],
    pointsBadge: '3x Pontos',
    status: _PromoStatus.ativa,
    statusLabel: 'No Feed do App',
    statusColor: AppColors.success,
    timeLabel: 'Ontem às 14:15',
    audienceLabel: 'Exclusivo Clientes Gold',
    audienceIcon: Icons.workspace_premium_outlined,
    audienceColor: AppColors.accent,
    message: 'Coleção outono com 3x pontos para clientes Gold. Renove seu '
        'estilo com benefícios exclusivos!',
    stats: [
      _Stat(Icons.visibility_outlined, '890', 'visualizações'),
      _Stat(Icons.touch_app_outlined, '98', 'cliques'),
      _Stat(Icons.trending_up, '11.0%', 'CTR'),
    ],
    actions: [
      _PromoAction(icon: Icons.phone_iphone, label: 'Ver no App'),
      _PromoAction(icon: Icons.edit_outlined, label: 'Editar'),
      _PromoAction(icon: Icons.pause_circle_outline, label: 'Pausar'),
    ],
  ),
  _PromoPost(
    imageIcon: Icons.local_pizza,
    imageGradient: const [Color(0xFFE57373), Color(0xFFC62828)],
    pointsBadge: '+50 Pontos',
    status: _PromoStatus.agendada,
    statusLabel: 'Agendada',
    statusColor: AppColors.primary,
    timeLabel: 'Agendado para: Amanhã às 18:00',
    audienceLabel: 'Feed + Push Notification',
    audienceIcon: Icons.notifications_active_outlined,
    message: 'Sexta da Pizza em Dobro: comprando qualquer pizza família, '
        'ganhe 50 pontos extras imediatos!',
    infoNote: 'O disparo automático será realizado simultaneamente no feed e via push.',
    stats: const [],
    actions: [
      _PromoAction(icon: Icons.edit_calendar_outlined, label: 'Editar Agendamento'),
      _PromoAction(icon: Icons.rocket_launch_outlined, label: 'Publicar Agora', primary: true),
      _PromoAction(icon: Icons.delete_outline, label: '', danger: true),
    ],
  ),
  _PromoPost(
    imageIcon: Icons.card_giftcard,
    imageGradient: const [Color(0xFF7E57C2), Color(0xFF4527A0)],
    pointsBadge: '500 Bônus',
    status: _PromoStatus.expirada,
    statusLabel: 'Expirada',
    statusColor: AppColors.textMuted,
    timeLabel: 'Veiculação: 01/Out a 07/Out',
    audienceLabel: 'Meta Atingida (100%)',
    audienceIcon: Icons.check_circle_outline,
    audienceColor: AppColors.success,
    message: 'Semana do Cliente: Ganhe 500 pontos bônus no seu primeiro '
        'resgate do mês!',
    stats: [
      _Stat(Icons.visibility_outlined, '3.820', 'visualizações'),
      _Stat(Icons.touch_app_outlined, '540', 'cliques'),
      _Stat(Icons.redeem_outlined, '142', 'resgates gerados'),
    ],
    actions: [
      _PromoAction(icon: Icons.bar_chart_rounded, label: 'Ver Relatório'),
      _PromoAction(icon: Icons.replay_outlined, label: 'Republicar'),
    ],
  ),
];

class _PromoCard extends StatelessWidget {
  final _PromoPost promo;
  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth > 640;
            final image = _buildImage();
            final body = _buildBody();
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  image,
                  const SizedBox(width: 18),
                  Expanded(child: body),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: double.infinity, child: image),
                const SizedBox(height: 14),
                body,
              ],
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
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: promo.imageGradient,
          ),
        ),
        child: Stack(
          children: [
            Center(child: Icon(promo.imageIcon, color: Colors.white70, size: 46)),
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  promo.pointsBadge,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera_outlined, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Post Feed',
                      style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w600),
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

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: promo.statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  promo.statusLabel,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: promo.statusColor,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  promo.timeLabel,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (promo.audienceColor ?? AppColors.textMuted).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(promo.audienceIcon, size: 13, color: promo.audienceColor ?? AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    promo.audienceLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: promo.audienceColor ?? AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          promo.message,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            height: 1.4,
          ),
        ),
        if (promo.infoNote != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    promo.infoNote!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (promo.stats.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              for (final stat in promo.stats)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stat.icon, size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      stat.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stat.label,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (final action in promo.actions)
              if (action.danger)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(action.icon, size: 17, color: AppColors.danger),
                )
              else if (action.primary)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(action.icon, size: 16),
                  label: Text(action.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(action.icon, size: 15),
                  label: Text(action.label),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}
