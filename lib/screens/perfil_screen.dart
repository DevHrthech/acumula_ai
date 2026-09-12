import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meu Perfil',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildProfileCard(theme),
                  const SizedBox(height: 18),
                  _buildStatsRow(theme),
                  const SizedBox(height: 18),
                  _buildMenu(theme),
                  const SizedBox(height: 18),
                  _buildLogoutButton(theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.primary, theme.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardBg,
              border: Border.all(color: theme.cardBg, width: 3),
            ),
            child: Center(
              child: Text(
                'R',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rodrigo Mendes',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'rodrigo@exemplo.com',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Nível Ouro',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeProvider theme) {
    final stats = const [
      _StatData('2.450', 'Pontos', Icons.star_rounded),
      _StatData('12', 'Selos', Icons.bookmark_outline),
      _StatData('7', 'Resgates', Icons.card_giftcard),
    ];
    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: s == stats.last ? 0 : 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(s.icon, color: theme.primary, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        s.value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMenu(ThemeProvider theme) {
    final items = const [
      _MenuItem('Histórico de Pontos', Icons.history),
      _MenuItem('Cupons Ativos', Icons.confirmation_number_outlined),
      _MenuItem('Indicar Amigos', Icons.share_outlined),
      _MenuItem('Notificações', Icons.notifications_none),
      _MenuItem('Ajuda e Suporte', Icons.help_outline),
    ];
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: theme.primary, size: 20),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textDark,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: theme.textHint,
                ),
                onTap: () {},
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: theme.border),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeProvider theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout, size: 18, color: Colors.red),
        label: const Text(
          'Sair da conta',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCC8C8)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

class _MenuItem {
  final String title;
  final IconData icon;
  const _MenuItem(this.title, this.icon);
}
