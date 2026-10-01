import 'package:flutter/material.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import '../widgets/promo_catalog.dart';
import 'detalhe_promo_screen.dart';

class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Todas';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await ClienteSessionScope.of(context).carregarVinculos();
    } catch (_) {
      // Mantém a tela usável mesmo se a rede falhar — lista fica vazia.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PromoDetailData> _dados(List<dynamic> vinculos) {
    return vinculos.map((v) => PromoDetailData.fromVinculo(v as Map<String, dynamic>)).toList();
  }

  List<String> _categorias(List<PromoDetailData> dados) {
    final categorias = dados.map((d) => d.storeCategory).whereType<String>().toSet().toList()..sort();
    return ['Todas', ...categorias];
  }

  List<PromoDetailData> _filtrados(List<PromoDetailData> dados) {
    final termo = _searchController.text.trim().toLowerCase();
    return dados.where((d) {
      if (_selectedFilter != 'Todas' && d.storeCategory != _selectedFilter) return false;
      if (termo.isEmpty) return true;
      return d.storeName.toLowerCase().contains(termo) || (d.storeCategory?.toLowerCase().contains(termo) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
        final dados = _dados(session.vinculos);
        final categorias = _categorias(dados);
        final filtrados = _filtrados(dados);
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 8),
                      _buildSearch(theme),
                      const SizedBox(height: 14),
                      _buildFilterChips(theme, categorias),
                      const SizedBox(height: 14),
                      Expanded(child: RefreshIndicator(onRefresh: _carregar, child: _buildList(theme, filtrados))),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Promoções', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 2),
          Text('Suas lojas e recompensas', style: TextStyle(fontSize: 13, color: theme.textMuted)),
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
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar promoções, lojas...',
            hintStyle: TextStyle(color: theme.textHint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: theme.textHint),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeProvider theme, List<String> categorias) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categorias.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final categoria = categorias[i];
          final selected = categoria == _selectedFilter;
          return InkWell(
            onTap: () => setState(() => _selectedFilter = categoria),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? theme.primary : theme.cardBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: selected ? theme.primary : theme.border),
              ),
              child: Text(
                categoria,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? (theme.isDarkMode ? Colors.black : Colors.white) : theme.textDark),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(ThemeProvider theme, List<PromoDetailData> dados) {
    if (dados.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Nenhuma promoção encontrada. Vá em "Buscar" pra vincular uma loja.', textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted)),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: dados.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _PromoCard(theme: theme, data: dados[i]),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final ThemeProvider theme;
  final PromoDetailData data;

  const _PromoCard({required this.theme, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [data.corPrincipal, data.corPrincipal.withValues(alpha: 0.6)]),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.storefront, color: Colors.white54, size: 40)),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(99)),
                    child: Text('${data.currentStamps}/${data.totalStamps}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primary)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.storeName, style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(data.rewardDescription, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.textDark, height: 1.3)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetalhePromoScreen(data: data))),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: theme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                    child: Text('Detalhes', style: TextStyle(color: theme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
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
