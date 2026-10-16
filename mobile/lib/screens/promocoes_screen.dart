import 'package:flutter/material.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import '../widgets/loja_logo.dart';
import '../widgets/promo_catalog.dart';

/// Aba "Promoções": avisos/posts publicados pelas lojas em que o cliente está
/// vinculado. É só informativa — não gera cartão fidelidade (os cartões das
/// campanhas ficam na tela Início).
class PromocoesScreen extends StatefulWidget {
  const PromocoesScreen({super.key});

  @override
  State<PromocoesScreen> createState() => _PromocoesScreenState();
}

class _PromocoesScreenState extends State<PromocoesScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'Todas';
  bool _carregando = true;
  bool _falhou = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await ClienteSessionScope.of(context).carregarPromocoes();
      if (mounted) setState(() => _falhou = false);
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _categoria(Map<String, dynamic> promo) =>
      (promo['empresa'] as Map<String, dynamic>)['categoria'] as String?;

  List<String> _categorias(List<dynamic> promos) {
    final categorias =
        promos
            .map((p) => _categoria(p as Map<String, dynamic>))
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return ['Todas', ...categorias];
  }

  List<dynamic> _filtradas(List<dynamic> promos) {
    final termo = _searchController.text.trim().toLowerCase();
    return promos.where((p) {
      final promo = p as Map<String, dynamic>;
      if (_selectedFilter != 'Todas' && _categoria(promo) != _selectedFilter) {
        return false;
      }
      if (termo.isEmpty) return true;
      final loja =
          ((promo['empresa'] as Map<String, dynamic>)['nome'] as String)
              .toLowerCase();
      final titulo = (promo['titulo'] as String).toLowerCase();
      final descricao = (promo['descricao'] as String? ?? '').toLowerCase();
      return loja.contains(termo) ||
          titulo.contains(termo) ||
          descricao.contains(termo);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
        final promos = session.promocoes;
        final categorias = _categorias(promos);
        final filtradas = _filtradas(promos);
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
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _carregar,
                          child: _buildList(theme, filtradas, promos.isEmpty),
                        ),
                      ),
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
            'Novidades e ofertas das suas lojas',
            style: TextStyle(fontSize: 13, color: theme.textMuted),
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
          style: TextStyle(color: theme.textDark),
          decoration: InputDecoration(
            hintText: 'Buscar promoções, lojas...',
            hintStyle: TextStyle(color: theme.textHint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: theme.textHint),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
                border: Border.all(
                  color: selected ? theme.primary : theme.border,
                ),
              ),
              child: Text(
                categoria,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? (theme.isDarkMode ? Colors.black : Colors.white)
                      : theme.textDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
    ThemeProvider theme,
    List<dynamic> promos,
    bool semNenhuma,
  ) {
    if (promos.isEmpty) {
      final texto = _falhou
          ? 'Não foi possível carregar as promoções. Puxe para atualizar.'
          : semNenhuma
          ? 'Nenhuma promoção por enquanto. Vincule-se a uma loja em "Buscar" para receber as novidades dela.'
          : 'Nenhuma promoção encontrada para essa busca.';
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textMuted),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: promos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) =>
          _PromoPost(theme: theme, promo: promos[i] as Map<String, dynamic>),
    );
  }
}

/// Card de aviso/post de uma loja — só informativo, sem progresso nem botão de
/// marcação.
class _PromoPost extends StatelessWidget {
  final ThemeProvider theme;
  final Map<String, dynamic> promo;

  const _PromoPost({required this.theme, required this.promo});

  String _data(String bruta) {
    final d = DateTime.parse(bruta).toUtc();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Período de validade: "De X até Y", "Até Y" ou nulo (sem data limite).
  String? _validade() {
    final inicio = promo['dataInicio'] as String?;
    final fim = promo['dataValidade'] as String?;
    if (fim == null) return null;
    return inicio == null
        ? 'Válida até ${_data(fim)}'
        : 'Válida de ${_data(inicio)} até ${_data(fim)}';
  }

  @override
  Widget build(BuildContext context) {
    final empresa = promo['empresa'] as Map<String, dynamic>;
    final cor = corDeHex(empresa['cor_principal'] as String);
    final destaque = corDeHex(empresa['cor_destaque'] as String);
    final descricao = promo['descricao'] as String?;
    final validade = _validade();
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
          // Faixa com as cores da marca da loja (principal + destaque), igual
          // aos cartões da tela Início.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cor, cor.withValues(alpha: 0.6)],
              ),
            ),
            child: Row(
              children: [
                LojaLogo(
                  url: logoDaEmpresa(empresa),
                  tamanho: 30,
                  icone: Icons.storefront,
                  corIcone: Colors.white,
                  fundo: logoDaEmpresa(empresa) == null ? Colors.transparent : Colors.white,
                  raio: 8,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    empresa['nome'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: destaque,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'PROMOÇÃO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo['titulo'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textDark,
                    height: 1.3,
                  ),
                ),
                if (descricao != null && descricao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    descricao,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: theme.textDark,
                      height: 1.4,
                    ),
                  ),
                ],
                if (validade != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: cor),
                      const SizedBox(width: 4),
                      Text(
                        validade,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
