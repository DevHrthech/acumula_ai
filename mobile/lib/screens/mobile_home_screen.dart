import 'package:flutter/material.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import '../widgets/campaign_models.dart';
import '../widgets/campaign_widgets.dart';
import '../widgets/promo_catalog.dart';
import '../widgets/section_label.dart';
import 'atividades_screen.dart';
import 'detalhe_promo_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final session = ClienteSessionScope.of(context);
      await Future.wait([
        session.carregarVinculos(),
        session.carregarResumo(),
        // Campanhas são cartões extras: se falharem, o resto da tela segue.
        session.carregarCampanhas().catchError((_) {}),
      ]);
    } catch (_) {
      // Mantém a tela utilizável mesmo se a rede falhar — vínculos ficam
      // vazios e o estado de "sem lojas ainda" é mostrado.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _openDetails(BuildContext context, PromoDetailData data) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetalhePromoScreen(data: data)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
        final vinculos = session.vinculos;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(theme, session),
                        const SizedBox(height: 16),
                        _buildPointsCard(theme, session),
                        const SizedBox(height: 18),
                        if (vinculos.isEmpty)
                          _buildEmptyState(theme)
                        else ...[
                          _buildFeaturedCampaign(context, theme, vinculos.first as Map<String, dynamic>),
                          if (vinculos.length > 1) ...[
                            const SizedBox(height: 28),
                            SectionLabel(theme: theme, title: 'Suas Lojas'),
                            const SizedBox(height: 14),
                            ...vinculos.skip(1).map((v) {
                              final data = PromoDetailData.fromVinculo(v as Map<String, dynamic>);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => _openDetails(context, data),
                                  child: CampaignListTile(
                                    theme: theme,
                                    campaign: Campaign(
                                      name: data.storeName,
                                      stamps: '${data.currentStamps}/${data.totalStamps} ${data.unidade}',
                                      icon: Icons.storefront_outlined,
                                      iconBg: data.corPrincipal.withValues(alpha: 0.15),
                                      progress: data.progress,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                          if (session.campanhas.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            SectionLabel(theme: theme, title: 'Campanhas'),
                            const SizedBox(height: 14),
                            ...session.campanhas.map((c) {
                              final data = promoDeCampanha(c as Map<String, dynamic>);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () => _openDetails(context, data),
                                  child: CampaignListTile(
                                    theme: theme,
                                    campaign: Campaign(
                                      name: data.campanhaNome ?? data.storeName,
                                      stamps: '${data.storeName} · ${data.currentStamps}/${data.totalStamps} ${data.unidade}',
                                      icon: Icons.local_activity_outlined,
                                      iconBg: data.corPrincipal.withValues(alpha: 0.15),
                                      progress: data.progress,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider theme, ClienteSession session) {
    final nome = (session.cliente?['nome'] as String?)?.split(' ').first ?? '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                border: Border.all(color: theme.cardBg, width: 2),
              ),
              child: Center(child: Icon(Icons.person, color: theme.cardBg, size: 24)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, $nome!', style: TextStyle(fontSize: 13, color: theme.textMuted)),
                Text('Acumula Aí', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primary)),
              ],
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.cardBg,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
          ),
          child: IconButton(
            tooltip: 'Atividades',
            icon: Icon(Icons.notifications_none, color: theme.primary),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AtividadesScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsCard(ThemeProvider theme, ClienteSession session) {
    final saldoTotal = session.resumo?['saldoTotal'] as int? ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary, theme.primaryDark]),
        boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Opacity(
              opacity: 0.18,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Center(child: Icon(Icons.change_history, color: theme.primary, size: 80)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo Total', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text('$saldoTotal', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.accent, height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 40, color: theme.textMuted),
          const SizedBox(height: 12),
          Text(
            'Você ainda não está vinculado a nenhuma loja.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Vá em "Buscar" e digite o código divulgado pela loja.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCampaign(BuildContext context, ThemeProvider theme, Map<String, dynamic> vinculo) {
    final data = PromoDetailData.fromVinculo(vinculo);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [data.corPrincipal, data.corPrincipal.withValues(alpha: 0.6)]),
            ),
            child: Center(child: Icon(Icons.storefront, color: Colors.white70, size: 48)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.progress >= 0.7)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.accent, borderRadius: BorderRadius.circular(99)),
                    child: Text('Quase lá!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textDark)),
                  ),
                const SizedBox(height: 10),
                Text(data.storeName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.textDark)),
                const SizedBox(height: 6),
                Text(data.rewardDescription, style: TextStyle(fontSize: 13, color: theme.textMuted, height: 1.4)),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progresso ${(data.progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.textDark)),
                    Text('${data.currentStamps}/${data.totalStamps} ${data.unidade}', style: TextStyle(fontSize: 12, color: theme.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                CampaignProgressBar(theme: theme, progress: data.progress),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _openDetails(context, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ver Detalhes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
