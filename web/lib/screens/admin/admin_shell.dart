import 'package:flutter/material.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_empresas_screen.dart';
import 'admin_planos_screen.dart';
import 'admin_monitoramento_screen.dart';
import 'admin_usuarios_screen.dart';
import 'admin_login_screen.dart';

enum _AdminSecao { empresas, planos, monitoramento, usuarios }

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
          backgroundColor: theme.bgPage,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 272,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.primary, theme.primaryDark],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2RL Admin',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'PAINEL DE GESTÃO',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'MENU PRINCIPAL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      _ItemMenu(
                        icone: Icons.people_alt_outlined,
                        label: 'Usuários',
                        selecionado: _secao == _AdminSecao.usuarios,
                        onTap: () => setState(() => _secao = _AdminSecao.usuarios),
                      ),
                      const Spacer(),
                      Divider(color: Colors.white.withValues(alpha: 0.12), height: 1, indent: 20, endIndent: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AdminAvatar(
                                  nome: widget.session.nome ?? '?',
                                  tamanho: 36,
                                  corTexto: Colors.white,
                                  corFundo: Colors.white.withValues(alpha: 0.15),
                                  corBorda: Colors.white.withValues(alpha: 0.25),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.session.nome ?? 'Administrador',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text(
                                        widget.session.email ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _sair,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: Colors.white.withValues(alpha: 0.75), size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sair do Painel',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: switch (_secao) {
                  _AdminSecao.empresas => AdminEmpresasScreen(session: widget.session),
                  _AdminSecao.planos => AdminPlanosScreen(session: widget.session),
                  _AdminSecao.monitoramento => AdminMonitoramentoScreen(session: widget.session),
                  _AdminSecao.usuarios => const AdminUsuariosScreen(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Material(
        color: selecionado ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icone, color: Colors.white, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
