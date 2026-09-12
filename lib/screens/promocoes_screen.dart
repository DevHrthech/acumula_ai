import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../widgets/promo_catalog.dart';
import 'detalhe_promo_screen.dart';

class Promotion {
  final String title;
  final String store;
  final String tag;
  final Color tagColor;
  final String emoji;
  final String? highlight;
  final List<Color> gradient;

  const Promotion({
    required this.title,
    required this.store,
    required this.tag,
    required this.tagColor,
    required this.emoji,
    required this.gradient,
    this.highlight,
  });
}

class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;

  static const _filters = ['Todas', 'Lojas', 'Cafeterias', 'Restaurantes'];

  static final List<Promotion> _promos = [
    const Promotion(
      title: 'Café Grátis a cada 10 compras',
      store: 'Artisan Coffee',
      tag: 'Quase lá!',
      tagColor: AppColors.accent,
      emoji: '☕',
      highlight: '+250 pts',
      gradient: [Color(0xFF8B5E3C), Color(0xFF4B2E1F)],
    ),
    const Promotion(
      title: '20% OFF em cortes',
      store: 'Studio Estrela',
      tag: 'Novo',
      tagColor: Color(0xFFE9D5F5),
      emoji: '✂️',
      gradient: [Color(0xFF5B0A8F), Color(0xFF3F0664)],
    ),
    const Promotion(
      title: 'Compre 1, leve 2 em bolos',
      store: 'Grão & Arte',
      tag: 'Voucher',
      tagColor: Color(0xFFE0F2E9),
      emoji: '🍰',
      highlight: '1/10',
      gradient: [Color(0xFFE91E63), Color(0xFFAD1457)],
    ),
    const Promotion(
      title: 'Pontos em dobro na quarta',
      store: 'Padoca do Bairro',
      tag: 'Quarta',
      tagColor: AppColors.accent,
      emoji: '🥐',
      gradient: [Color(0xFFFF8A65), Color(0xFFD84315)],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 8),
                _buildSearch(theme),
                const SizedBox(height: 14),
                _buildFilterChips(theme),
                const SizedBox(height: 14),
                Expanded(child: _buildList(theme)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Promoções',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: theme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ofertas exclusivas pra você',
                style: TextStyle(fontSize: 13, color: theme.textMuted),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.cardBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.tune, color: theme.primary, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar promoções, lojas...',
            hintStyle: TextStyle(color: theme.textHint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: theme.textHint),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeProvider theme) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedFilter;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = i),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? theme.primary : theme.cardBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? theme.primary : theme.border,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? (theme.isDarkMode ? Colors.black : Colors.white) : theme.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(ThemeProvider theme) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _promos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final idx = i + 1;
        final data = idx < PromoCatalog.list.length
            ? PromoCatalog.list[idx]
            : PromoCatalog.list.first;
        return _PromoCard(theme: theme, promo: _promos[i], data: data);
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  final ThemeProvider theme;
  final Promotion promo;
  final PromoDetailData data;

  const _PromoCard({required this.theme, required this.promo, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      data.imageAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: promo.tagColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        promo.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  if (promo.highlight != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          promo.highlight!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.store,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  promo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetalhePromoScreen(data: data),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'Detalhes',
                          style: TextStyle(
                            color: theme.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text(
                          'Resgatar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
