import 'package:flutter/material.dart';
import '../utils/mascaras.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/cliente_api.dart';
import '../services/google_auth.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'cadastro_screen.dart';
import 'completar_google_screen.dart';
import 'mobile_root_screen.dart';
import 'recuperar_senha_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePassword() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _abrirRecuperacao() async {
    final redefiniu = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => RecuperarSenhaScreen(cpfInicial: _cpfController.text.trim())),
    );
    if (redefiniu == true && mounted) {
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida! Entre com a nova senha.')),
      );
    }
  }

  Future<void> _entrarComGoogle() async {
    if (!GoogleAuth.disponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O login com Google ainda não está disponível. Entre com seu CPF e senha.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final idToken = await GoogleAuth.obterIdToken();
      if (idToken == null) {
        setState(() => _erro = 'Não foi possível obter a identificação do Google.');
        return;
      }

      if (!mounted) return;
      final pendente = await ClienteSessionScope.of(context).loginGoogle(idToken);
      if (!mounted) return;

      if (pendente == null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MobileRootScreen()));
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompletarGoogleScreen(
              nome: pendente['nome'] as String,
              email: pendente['email'] as String,
              tokenCadastro: pendente['tokenCadastro'] as String,
            ),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled && mounted) {
        setState(() => _erro = 'Não foi possível entrar com o Google. Tente novamente.');
      }
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível entrar com o Google. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = ClienteSessionScope.of(context);
      await session.login(_cpfController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileRootScreen()),
      );
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (e) {
      if (mounted) setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _criarConta() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.isDarkMode
                    ? [
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                        const Color(0xFF0F3460),
                      ]
                    : [
                        const Color(0xFFE9D5F5),
                        const Color(0xFFFCE7F3),
                        const Color(0xFFFFF6E5),
                      ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.change_history,
                          color: theme.accent,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Acumula Aí',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Suas recompensas em um só lugar',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'CPF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _cpfController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [cpfFormatter],
                            decoration: _inputDecoration(theme,
                              hint: '000.000.000-00',
                              prefixIcon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Senha',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: _abrirRecuperacao,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                color: theme.textHint,
                                fontSize: 18,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.textHint,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: theme.textHint,
                                ),
                                onPressed: _togglePassword,
                              ),
                              filled: true,
                              fillColor: theme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),
                              border: _outlineBorder(theme),
                              enabledBorder: _outlineBorder(theme),
                              focusedBorder: _outlineBorder(theme,
                                color: theme.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _erro!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                                elevation: 4,
                                shadowColor:
                                    theme.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _carregando
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: theme.isDarkMode ? Colors.black : Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OU CONTINUE COM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textHint,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.border)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  theme: theme,
                                  label: 'Google',
                                  iconWidget: _GoogleIcon(isDarkMode: theme.isDarkMode),
                                  onPressed: _carregando ? () {} : _entrarComGoogle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ainda não tem uma conta? ',
                          style: TextStyle(
                            color: theme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _criarConta,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              color: theme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: theme.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SEGURO',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textHint,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: theme.textHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'OFICIAL',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textHint,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

OutlineInputBorder _outlineBorder(ThemeProvider theme, {
  Color? color,
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color ?? theme.border, width: width),
  );
}

InputDecoration _inputDecoration(ThemeProvider theme, {
  required String hint,
  required IconData prefixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: theme.textHint, fontSize: 15),
    prefixIcon: Icon(prefixIcon, color: theme.textHint),
    filled: true,
    fillColor: theme.surface,
    contentPadding:
        const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    border: _outlineBorder(theme),
    enabledBorder: _outlineBorder(theme),
    focusedBorder: _outlineBorder(theme,
      color: theme.primary,
      width: 1.5,
    ),
  );
}



class _SocialButton extends StatelessWidget {
  final ThemeProvider theme;
  final String label;
  final Widget iconWidget;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.theme,
    required this.label,
    required this.iconWidget,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.cardBg,
          side: BorderSide(color: theme.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textDark),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  final bool isDarkMode;
  const _GoogleIcon({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: isDarkMode ? Colors.white24 : const Color(0xFFE0E0E0)),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
        ),
      ),
    );
  }
}
