import 'package:flutter/material.dart';
import 'screens/admin/admin_login_screen.dart';
import 'state/admin_session.dart';
import 'theme/theme_provider.dart';

/// Entrypoint separado do painel interno da 2RL (gestão de empresas,
/// licenças e contratos) — build/deploy isolados do app da Empresa
/// (main.dart) por questão de segurança: bundle JS próprio, publicado
/// num subdomínio dedicado, não linkado do site público.
void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AdminSession();
    return ThemeScope(
      child: Builder(
        builder: (context) {
          final themeProvider = ThemeScope.of(context);
          return ListenableBuilder(
            listenable: themeProvider,
            builder: (context, child) {
              return MaterialApp(
                title: '2RL Admin',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.themeData,
                home: AdminLoginScreen(session: session),
              );
            },
          );
        },
      ),
    );
  }
}
