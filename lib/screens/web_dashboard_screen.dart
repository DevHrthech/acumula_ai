import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

class WebDashboardScreen extends StatelessWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebDashboardScreen({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.dashboard,
      onSelect: onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebPageHeader(
              title: 'Dashboard Principal',
              subtitle:
                  'Visão geral do desempenho de fidelidade e campanhas ativas.',
            ),
            const SizedBox(height: 28),
            _buildKpiRow(),
            const SizedBox(height: 20),
            _buildMiddleRow(),
            const SizedBox(height: 20),
            _buildActivityTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 800;
        final cards = [
          _KpiCard(
            icon: Icons.payments_outlined,
            iconColor: AppColors.primary,
            label: 'VENDAS TOTAIS',
            value: 'R\$ 45.280,00',
            trend: '~12%',
            showChart: true,
          ),
          _KpiCard(
            icon: Icons.person_add_alt,
            iconColor: AppColors.accent,
            label: 'NOVOS CLIENTES',
            value: '1.248',
            progress: 0.75,
            progressLabel: '75% da meta mensal',
          ),
          _KpiCard(
            icon: Icons.campaign_outlined,
            iconColor: Colors.white,
            label: 'CAMPANHAS ATIVAS',
            value: '08',
            button: 'Ver Detalhes',
            isAccent: true,
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

  Widget _buildMiddleRow() {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 800;
        final chart = const _ChartCard();
        final donut = const _DonutCard();
        if (wide) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: chart),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: donut),
              ],
            ),
          );
        }
        return Column(
          children: [chart, const SizedBox(height: 16), donut],
        );
      },
    );
  }

  Widget _buildActivityTable() {
    final rows = const [
      _ActivityRow('RM', 'Ricardo Mendes', 'Resgate de Voucher', 'Há 5 min',
          '500 pts', 'Concluído', true),
      _ActivityRow('AS', 'Ana Souza', 'Nova Compra', 'Há 12 min',
          'R\$ 150,00', 'Processando', false),
      _ActivityRow('FL', 'Felipe Lima', 'Cadastro no Programa', 'Há 45 min',
          '-', 'Sucesso', true),
    ];
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Atividades Recentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Ver tudo',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              children: [
                _Cell('Cliente', isHeader: true, flex: 2),
                _Cell('Ação', isHeader: true, flex: 2),
                _Cell('Data', isHeader: true, flex: 1),
                _Cell('Valor', isHeader: true, flex: 1),
                _Cell('Status', isHeader: true, flex: 1),
              ],
            ),
          ),
          ...rows.map(
            (r) => Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _ClientCell(initials: r.initials, name: r.name, flex: 2),
                  _Cell(r.action, flex: 2),
                  _Cell(r.date, flex: 1, color: AppColors.textMuted),
                  _Cell(r.value, flex: 1, fontWeight: FontWeight.w600),
                  Expanded(
                    flex: 1,
                    child: _StatusChip(
                      label: r.status,
                      isPositive: r.isPositive,
                    ),
                  ),
                ],
              ),
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

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? trend;
  final bool showChart;
  final double? progress;
  final String? progressLabel;
  final String? button;
  final bool isAccent;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.trend,
    this.showChart = false,
    this.progress,
    this.progressLabel,
    this.button,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isAccent
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAccent
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    trend!,
                    style: const TextStyle(
                      color: AppColors.successText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
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
          if (showChart) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: CustomPaint(painter: _MiniBarPainter()),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progressLabel ?? '',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (button != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  button!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendas Semanais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Últimos 7 dias',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  const _DonutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Meta Trimestral',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(140, 140),
                  painter: _DonutPainter(progress: 0.7),
                ),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '70%',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Meta alcançada',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Meta de resgates para este trimestre: 5.000 pontos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow {
  final String initials;
  final String name;
  final String action;
  final String date;
  final String value;
  final String status;
  final bool isPositive;
  const _ActivityRow(
    this.initials,
    this.name,
    this.action,
    this.date,
    this.value,
    this.status,
    this.isPositive,
  );
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
          fontWeight: fontWeight ??
              (isHeader ? FontWeight.w700 : FontWeight.w500),
          color: color ??
              (isHeader ? AppColors.textMuted : AppColors.textDark),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isPositive;
  const _StatusChip({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final bg = isPositive ? AppColors.successBg : AppColors.warningBg;
    final fg = isPositive ? AppColors.successText : AppColors.warningText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const data = [0.45, 0.6, 0.4, 0.7, 0.55, 0.85, 0.95];
    const labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final w = size.width;
    final h = size.height - 20;
    final stepX = w / (data.length - 1);

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = h * (1 - data[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(w, h);
    fillPath.close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fill);

    final line = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    final dot = Paint()..color = AppColors.primary;
    for (var i = 0; i < data.length; i++) {
      final x = stepX * i;
      final y = h * (1 - data[i]);
      canvas.drawCircle(Offset(x, y), 4, dot);
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(Offset(x, y), 2.5, dot);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutPainter extends CustomPainter {
  final double progress;
  _DonutPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final bg = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final values = [0.4, 0.55, 0.35, 0.7, 0.5, 0.85, 0.75];
    final w = size.width;
    final h = size.height;
    final gap = 4.0;
    final barW = (w - gap * (values.length - 1)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final x = i * (barW + gap);
      final barH = h * values[i];
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, h - barH, barW, barH),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = i == values.length - 1
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
