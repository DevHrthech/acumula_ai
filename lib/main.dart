import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/theme_provider.dart';

void main() {
  runApp(const AcumulaAiApp());
}

class AcumulaAiApp extends StatefulWidget {
  const AcumulaAiApp({super.key});

  static const double kMobileBreakpoint = 800;

  @override
  State<AcumulaAiApp> createState() => _AcumulaAiAppState();
}

class _AcumulaAiAppState extends State<AcumulaAiApp> {
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
                title: 'Acumula Aí',
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(),
                darkTheme: ThemeData.dark(),
                home: AnimatedTheme(
                  data: themeProvider.themeData,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: const LoginScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
