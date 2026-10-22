import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/web_root_screen.dart';
import 'services/empresa_api.dart';
import 'state/empresa_config.dart';
import 'state/empresa_session.dart';
import 'theme/theme_provider.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const AcumulaAiApp());
}

class AcumulaAiApp extends StatelessWidget {
  const AcumulaAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return EmpresaSessionScope(
      child: EmpresaConfigScope(
        child: ThemeScope(
          child: Builder(
            builder: (context) {
              final themeProvider = ThemeScope.of(context);
              return ListenableBuilder(
                listenable: themeProvider,
                builder: (context, child) {
                  return MaterialApp(
                    navigatorKey: _navigatorKey,
                    title: 'Acumula Aí',
                    debugShowCheckedModeBanner: false,
                    // O painel é claro (campos com fundo claro fixo, sem botão de
                    // modo escuro). Seguir o tema do Windows deixava o texto dos
                    // campos quase branco nas telas abertas por navegação (ex.:
                    // depois do login). Todas as rotas usam o tema do app.
                    theme: themeProvider.themeData,
                    darkTheme: themeProvider.themeData,
                    themeMode: ThemeMode.light,
                    home: AnimatedTheme(
                      data: themeProvider.themeData,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: const _Inicio(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tela inicial: tenta retomar a sessão guardada no navegador antes de decidir
/// entre o painel e o login. Também registra o que fazer quando a API recusa
/// o token no meio do uso (expirado).
class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  bool _restaurando = true;
  bool _autenticado = false;

  @override
  void initState() {
    super.initState();
    final session = EmpresaSessionScope.of(context);
    EmpresaApi.aoSessaoExpirar = () {
      session.logout();
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    };
    _restaurar();
  }

  Future<void> _restaurar() async {
    final session = EmpresaSessionScope.of(context);
    final config = EmpresaConfigScope.of(context);
    final ok = await session.restaurar();
    if (ok) config.carregarDe(session.empresa!);
    if (!mounted) return;
    setState(() {
      _autenticado = ok;
      _restaurando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _autenticado ? const WebRootScreen() : const LoginScreen();
  }
}
