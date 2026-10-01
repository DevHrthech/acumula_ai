import 'package:flutter/material.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import 'admin_empresas_screen.dart';
import 'admin_planos_screen.dart';
import 'admin_monitoramento_screen.dart';
import 'admin_login_screen.dart';

enum _AdminSecao { empresas, planos, monitoramento }

class AdminShell extends StatefulWidget {
  final AdminSession session;
  const AdminShell({super.key, required this.session});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  _AdminSecao _secao = _AdminSecao.empresas;

  void _sair() {
    widget.session.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminLoginScreen(session: widget.session)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 240,
                color: theme.isDarkMode ? const Color(0xFF16213E) : theme.primary,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
                      const SizedBox(height: 8),
                      const Text('2RL Admin', textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text(widget.session.email ?? '', textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                      const SizedBox(height: 24),
                      _ItemMenu(
                        icone: Icons.store_outlined,
                        label: 'Empresas',
                        selecionado: _secao == _AdminSecao.empresas,
                        onTap: () => setState(() => _secao = _AdminSecao.empresas),
                      ),
                      _ItemMenu(
                        icone: Icons.card_membership_outlined,
                        label: 'Planos',
                        selecionado: _secao == _AdminSecao.planos,
                        onTap: () => setState(() => _secao = _AdminSecao.planos),
                      ),
                      _ItemMenu(
                        icone: Icons.monitor_heart_outlined,
                        label: 'Monitoramento',
                        selecionado: _secao == _AdminSecao.monitoramento,
                        onTap: () => setState(() => _secao = _AdminSecao.monitoramento),
                      ),
                      const Spacer(),
                      _ItemMenu(icone: Icons.logout, label: 'Sair', selecionado: false, onTap: _sair),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: switch (_secao) {
                  _AdminSecao.empresas => AdminEmpresasScreen(session: widget.session),
                  _AdminSecao.planos => AdminPlanosScreen(session: widget.session),
                  _AdminSecao.monitoramento => AdminMonitoramentoScreen(session: widget.session),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  const _ItemMenu({required this.icone, required this.label, required this.selecionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selecionado ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icone, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
