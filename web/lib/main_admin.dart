import 'package:flutter/material.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_shell.dart';
import 'services/admin_api.dart';
import 'state/admin_session.dart';
import 'theme/theme_provider.dart';

/// Entrypoint separado do painel interno da 2RL (gestão de empresas,
/// licenças e contratos) — build/deploy isolados do app da Empresa
/// (main.dart) por questão de segurança: bundle JS próprio, publicado
/// num subdomínio dedicado, não linkado do site público.
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  // A sessão vive no State (não no build): reconstruir o app por troca de tema
  // não pode descartar o login.
  final _session = AdminSession();
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final Future<bool> _restauracao;

  @override
  void initState() {
    super.initState();
    // Token vencido no meio do uso: limpa a sessão e volta pro login.
    AdminApi.aoSessaoExpirar = () {
      _session.logout();
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AdminLoginScreen(session: _session)),
        (route) => false,
      );
    };
    _restauracao = _session.restaurar();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      child: Builder(
        builder: (context) {
          final themeProvider = ThemeScope.of(context);
          return ListenableBuilder(
            listenable: themeProvider,
            builder: (context, child) {
              return MaterialApp(
                navigatorKey: _navigatorKey,
                title: '2RL Admin',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.themeData,
                home: FutureBuilder<bool>(
                  future: _restauracao,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    return snapshot.data == true
                        ? AdminShell(session: _session)
                        : AdminLoginScreen(session: _session);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
