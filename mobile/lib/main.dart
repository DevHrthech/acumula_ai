import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/mobile_root_screen.dart';
import 'state/cliente_session.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(const AcumulaAiApp());
}

class AcumulaAiApp extends StatelessWidget {
  const AcumulaAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ClienteSessionScope(
      child: ThemeScope(
        child: Builder(
          builder: (context) {
            final themeProvider = ThemeScope.of(context);
            return ListenableBuilder(
              listenable: themeProvider,
              builder: (context, child) {
                return MaterialApp(
                  title: 'Acumula Aí',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData.light(),
                  darkTheme: ThemeData.dark(),
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
    );
  }
}

/// Primeira tela: tenta retomar a sessão guardada no aparelho. Com sessão
/// válida abre direto o app; sem ela (ou token expirado/recusado) cai no login.
class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  late final Future<bool> _restauracao;

  @override
  void initState() {
    super.initState();
    _restauracao = ClienteSessionScope.of(context).restaurar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return FutureBuilder<bool>(
      future: _restauracao,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: theme.bgPage,
            body: Center(child: CircularProgressIndicator(color: theme.primary)),
          );
        }
        return snapshot.data == true ? const MobileRootScreen() : const LoginScreen();
      },
    );
  }
}
