import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _biometricEnabled = true;

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
                    'Configurações',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preferências e segurança da sua conta',
                    style: TextStyle(fontSize: 13, color: theme.textMuted),
                  ),
                  const SizedBox(height: 18),
                  _buildSection(
                    theme: theme,
                    title: 'Notificações',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Notificações push',
                        subtitle: 'Promoções e novidades',
                        icon: Icons.notifications_active_outlined,
                        value: _pushEnabled,
                        onChanged: (v) => setState(() => _pushEnabled = v),
                      ),
                      _SwitchTile(
                        theme: theme,
                        title: 'E-mail marketing',
                        subtitle: 'Ofertas semanais por e-mail',
                        icon: Icons.email_outlined,
                        value: _emailEnabled,
                        onChanged: (v) => setState(() => _emailEnabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Segurança',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Login biométrico',
                        subtitle: 'Use digital ou Face ID',
                        icon: Icons.fingerprint,
                        value: _biometricEnabled,
                        onChanged: (v) => setState(() => _biometricEnabled = v),
                      ),
                      _NavTile(
                        theme: theme,
                        title: 'Alterar senha',
                        icon: Icons.lock_outline,
                        onTap: () {},
                      ),
                      _NavTile(
                        theme: theme,
                        title: 'Privacidade e dados',
                        icon: Icons.shield_outlined,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Aparência',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Modo escuro',
                        subtitle: 'Tema escuro do sistema',
                        icon: Icons.dark_mode_outlined,
                        value: theme.isDarkMode,
                        onChanged: (v) => theme.toggleTheme(),
                      ),
                      _NavTile(
                        theme: theme,
                        title: 'Idioma',
                        icon: Icons.language_outlined,
                        trailing: 'Português (BR)',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Acumula Aí v1.0.0',
                      style: TextStyle(fontSize: 12, color: theme.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required ThemeProvider theme,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
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
            children: List.generate(children.length, (i) {
              return Column(
                children: [
                  children[i],
                  if (i != children.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: theme.border),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final ThemeProvider theme;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.theme,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textDark,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: theme.textMuted,
              ),
            ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: theme.primary,
    );
  }
}

class _NavTile extends StatelessWidget {
  final ThemeProvider theme;
  final String title;
  final IconData icon;
  final String? trailing;
  final VoidCallback onTap;

  const _NavTile({
    required this.theme,
    required this.title,
    required this.icon,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: theme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.textDark,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 13,
                color: theme.textMuted,
              ),
            ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: theme.textHint),
        ],
      ),
    );
  }
}
