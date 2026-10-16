import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import '../widgets/promo_catalog.dart';

class DetalhePromoScreen extends StatefulWidget {
  final PromoDetailData data;
  const DetalhePromoScreen({super.key, required this.data});

  @override
  State<DetalhePromoScreen> createState() => _DetalhePromoScreenState();
}

class _DetalhePromoScreenState extends State<DetalhePromoScreen> {
  bool _enviando = false;

  Future<void> _solicitarMarcacao() async {
    final cupomFiscal = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CupomFiscalDialog(),
    );
    if (cupomFiscal == null || !mounted) return;

    setState(() => _enviando = true);
    try {
      final session = ClienteSessionScope.of(context);
      await session.solicitarMarcacao(empresaId: widget.data.empresaId, cupomFiscal: cupomFiscal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação enviada! A loja vai validar sua compra em breve.')),
      );
    } on ClienteApiException catch (e) {
      // Ex.: "Você já tem uma solicitação aguardando validação nesta loja."
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível enviar a solicitação.')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.bgPage,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, theme),
                  const SizedBox(height: 16),
                  _buildHero(theme, data),
                  const SizedBox(height: 18),
                  _buildRewardCard(theme, data),
                  const SizedBox(height: 16),
                  _buildProgressCard(theme, data),
                  const SizedBox(height: 20),
                  _buildCta(context, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeProvider theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: Icon(Icons.arrow_back, color: theme.primary)),
        Text('Acumula Aí', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primary)),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildHero(ThemeProvider theme, PromoDetailData data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [data.corPrincipal, data.corPrincipal.withValues(alpha: 0.6)]),
        ),
        child: Stack(
          children: [
            const Center(child: Icon(Icons.storefront, color: Colors.white54, size: 56)),
            Positioned(
              left: 18,
              right: 18,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.campanhaNome != null)
                    const Text('CAMPANHA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  Text(data.campanhaNome ?? data.storeName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (data.campanhaNome != null)
                    Text(data.storeName, style: const TextStyle(color: Colors.white70, fontSize: 13))
                  else if (data.storeCategory != null)
                    Text(data.storeCategory!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(ThemeProvider theme, PromoDetailData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recompensa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Text(data.rewardDescription, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textDark, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeProvider theme, PromoDetailData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('SEU PROGRESSO ATUAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 18),
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _DonutPainter(theme: theme, progress: data.progress),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${data.currentStamps} / ${data.totalStamps}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.textDark)),
                    const SizedBox(height: 2),
                    Text(data.unidade.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _enviando ? null : _solicitarMarcacao,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _enviando
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: theme.isDarkMode ? Colors.black : Colors.white))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('SOLICITAR MARCAÇÃO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

/// Diálogo isolado num StatefulWidget próprio pra que o TextEditingController
/// seja descartado no dispose() do próprio diálogo — descartá-lo manualmente
/// logo após o showDialog() retornar quebra a animação de saída (o TextField
/// ainda em tela tenta usar o controller já destruído).
class _CupomFiscalDialog extends StatefulWidget {
  const _CupomFiscalDialog();

  @override
  State<_CupomFiscalDialog> createState() => _CupomFiscalDialogState();
}

class _CupomFiscalDialogState extends State<_CupomFiscalDialog> {
  final _cupomController = TextEditingController();

  @override
  void dispose() {
    _cupomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Solicitar marcação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informe o número do cupom fiscal, se tiver (opcional):'),
          const SizedBox(height: 12),
          TextField(
            controller: _cupomController,
            decoration: const InputDecoration(hintText: 'Ex: NFC-e 000.123.456', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_cupomController.text.trim()),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final ThemeProvider theme;
  final double progress;
  _DonutPainter({required this.theme, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2;

    final bg = Paint()
      ..color = theme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = theme.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
