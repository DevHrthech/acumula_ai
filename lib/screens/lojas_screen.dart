import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StoreItem {
  final String name;
  final String category;
  final String distance;
  final double rating;
  final String emoji;
  final List<Color> gradient;
  final String? tag;

  const StoreItem({
    required this.name,
    required this.category,
    required this.distance,
    required this.rating,
    required this.emoji,
    required this.gradient,
    this.tag,
  });
}

class LojasScreen extends StatefulWidget {
  const LojasScreen({super.key});

  @override
  State<LojasScreen> createState() => _LojasScreenState();
}

class _LojasScreenState extends State<LojasScreen> {
  int _selectedCategory = 0;
  static const _categories = ['Todas', 'Cafés', 'Beleza', 'Restaurantes', 'Mercados'];

  static final List<StoreItem> _stores = [
    const StoreItem(
      name: 'Artisan Coffee',
      category: 'Cafeteria',
      distance: '1.2 km',
      rating: 4.8,
      emoji: '☕',
      tag: 'Favorita',
      gradient: [Color(0xFF8B5E3C), Color(0xFF4B2E1F)],
    ),
    const StoreItem(
      name: 'Studio Estrela',
      category: 'Beleza',
      distance: '0.8 km',
      rating: 4.9,
      emoji: '✂️',
      gradient: [Color(0xFF5B0A8F), Color(0xFF3F0664)],
    ),
    const StoreItem(
      name: 'Grão & Arte Cafeteria',
      category: 'Cafeteria',
      distance: '2.3 km',
      rating: 4.6,
      emoji: '🍰',
      gradient: [Color(0xFFE91E63), Color(0xFFAD1457)],
    ),
    const StoreItem(
      name: 'Padoca do Bairro',
      category: 'Restaurante',
      distance: '0.5 km',
      rating: 4.7,
      emoji: '🥐',
      gradient: [Color(0xFFFF8A65), Color(0xFFD84315)],
    ),
    const StoreItem(
      name: 'Mercado Bom Preço',
      category: 'Mercado',
      distance: '3.1 km',
      rating: 4.4,
      emoji: '🛒',
      gradient: [Color(0xFF4CAF50), Color(0xFF1B5E20)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildCategories(),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lojas Participantes',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Encontre estabelecimentos perto de você',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou categoria',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedCategory;
          return InkWell(
            onTap: () => setState(() => _selectedCategory = i),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                _categories[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _stores.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _StoreCard(store: _stores[i]),
    );
  }
}

class _StoreCard extends StatelessWidget {
  final StoreItem store;
  const _StoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: store.gradient,
                ),
              ),
              child: Center(
                child: Text(
                  store.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (store.tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            store.tag!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    store.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textHint,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        store.distance,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
