import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import 'mobile_home_screen.dart';
import 'promocoes_screen.dart';
import 'perfil_screen.dart';
import 'configuracoes_screen.dart';
import 'vincular_loja_screen.dart';
import '../widgets/mobile_bottom_nav.dart';

/// Tela raiz do app mobile. Hospeda o bottom nav e troca o corpo
/// conforme a aba selecionada.
class MobileRootScreen extends StatefulWidget {
  const MobileRootScreen({super.key});

  @override
  State<MobileRootScreen> createState() => _MobileRootScreenState();
}

class _MobileRootScreenState extends State<MobileRootScreen> {
  int _tabIndex = 0;

  late final List<Widget> _pages = const [
    MobileHomeScreen(),
    VincularLojaScreen(),
    PromocoesScreen(),
    PerfilScreen(),
    ConfiguracoesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          color: theme.bgPage,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: IndexedStack(index: _tabIndex, children: _pages),
            bottomNavigationBar: MobileBottomNav(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ),
        );
      },
    );
  }
}
