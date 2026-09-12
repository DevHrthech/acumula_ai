import 'package:flutter/material.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.textDark,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
      error: AppColors.danger,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bgPage,
    fontFamily: 'Roboto',
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: Colors.black,
      secondary: AppColors.darkAccent,
      onSecondary: AppColors.darkTextDark,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextDark,
      error: AppColors.darkDanger,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: AppColors.darkBgPage,
    fontFamily: 'Roboto',
  );

  // Métodos auxiliares para obter cores de acordo com o tema
  Color get primary => _isDarkMode ? AppColors.darkPrimary : AppColors.primary;
  Color get primaryDark => _isDarkMode ? AppColors.darkPrimaryDark : AppColors.primaryDark;
  Color get accent => _isDarkMode ? AppColors.darkAccent : AppColors.accent;
  Color get textDark => _isDarkMode ? AppColors.darkTextDark : AppColors.textDark;
  Color get textMuted => _isDarkMode ? AppColors.darkTextMuted : AppColors.textMuted;
  Color get textHint => _isDarkMode ? AppColors.darkTextHint : AppColors.textHint;
  Color get border => _isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get surface => _isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get bgPage => _isDarkMode ? AppColors.darkBgPage : AppColors.bgPage;
  Color get cardBg => _isDarkMode ? AppColors.darkCardBg : AppColors.cardBg;
  Color get success => _isDarkMode ? AppColors.darkSuccess : AppColors.success;
  Color get successBg => _isDarkMode ? AppColors.darkSuccessBg : AppColors.successBg;
  Color get warning => _isDarkMode ? AppColors.darkWarning : AppColors.warning;
  Color get warningBg => _isDarkMode ? AppColors.darkWarningBg : AppColors.warningBg;
  Color get successText => _isDarkMode ? AppColors.darkSuccessText : AppColors.successText;
  Color get warningText => _isDarkMode ? AppColors.darkWarningText : AppColors.warningText;
  Color get danger => _isDarkMode ? AppColors.darkDanger : AppColors.danger;
  Color get dangerBg => _isDarkMode ? AppColors.darkDangerBg : AppColors.dangerBg;
  Color get inputBg => _isDarkMode ? AppColors.darkInputBg : AppColors.inputBg;
}

class ThemeScope extends StatefulWidget {
  final Widget child;

  const ThemeScope({super.key, required this.child});

  @override
  State<ThemeScope> createState() => ThemeScopeState();

  static ThemeProvider of(BuildContext context) {
    final ThemeScopeState? state = context.findAncestorStateOfType<ThemeScopeState>();
    assert(state != null, 'No ThemeScope found in context');
    return state!.themeProvider;
  }
}

class ThemeScopeState extends State<ThemeScope> {
  late final ThemeProvider themeProvider;

  @override
  void initState() {
    super.initState();
    themeProvider = ThemeProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, child) => _InheritedThemeScope(
        themeProvider: themeProvider,
        child: widget.child,
      ),
    );
  }
}

class _InheritedThemeScope extends InheritedWidget {
  final ThemeProvider themeProvider;

  const _InheritedThemeScope({
    required this.themeProvider,
    required super.child,
  });

  @override
  bool updateShouldNotify(_InheritedThemeScope oldWidget) {
    return themeProvider != oldWidget.themeProvider;
  }
}
