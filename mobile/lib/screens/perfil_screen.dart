import 'package:flutter/material.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      await ClienteSessionScope.of(context).carregarResumo();
    } catch (_) {
      // Tela continua usável mesmo se o resumo falhar ao carregar.
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _sair(BuildContext context) {
    ClienteSessionScope.of(context).logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
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
                        Text('Meu Perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
                        const SizedBox(height: 18),
                        _buildProfileCard(theme, session),
                        const SizedBox(height: 18),
                        _buildStatsRow(theme, session),
                        const SizedBox(height: 24),
                        _buildLogoutButton(theme, context),
                      ],
                    ),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeProvider theme, ClienteSession session) {
    final nome = (session.cliente?['nome'] as String?) ?? '';
    final contato = (session.cliente?['email'] as String?) ?? (session.cliente?['telefone'] as String? ?? '');
    final iniciais = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary, theme.primaryDark]),
        boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.cardBg, border: Border.all(color: theme.cardBg, width: 3)),
            child: Center(child: Text(iniciais, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primary))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nome, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(contato, style: const TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeProvider theme, ClienteSession session) {
    final resumo = session.resumo;
    final stats = [
      _StatData('${resumo?['saldoTotal'] ?? 0}', 'Saldo', Icons.star_rounded),
      _StatData('${resumo?['totalMarcacoes'] ?? 0}', 'Marcações', Icons.bookmark_outline),
      _StatData('${resumo?['totalResgates'] ?? 0}', 'Resgates', Icons.card_giftcard),
    ];
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == stats.last ? 0 : 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: theme.primary, size: 22),
                      const SizedBox(height: 6),
                      Text(s.value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
                      const SizedBox(height: 2),
                      Text(s.label, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLogoutButton(ThemeProvider theme, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _sair(context),
        icon: const Icon(Icons.logout, size: 18, color: Colors.red),
        label: const Text('Sair da conta', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCC8C8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: theme.cardBg,
        ),
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  const _StatData(this.value, this.label, this.icon);
}
