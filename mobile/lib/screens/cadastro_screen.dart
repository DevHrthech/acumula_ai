import 'package:flutter/material.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'mobile_root_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    FocusScope.of(context).unfocus();

    if (_nomeController.text.trim().isEmpty ||
        _cpfController.text.trim().isEmpty ||
        _telefoneController.text.trim().isEmpty ||
        _senhaController.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    if (_senhaController.text != _confirmarSenhaController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = ClienteSessionScope.of(context);
      await session.cadastro(
        nome: _nomeController.text.trim(),
        cpf: _cpfController.text.trim(),
        senha: _senhaController.text,
        telefone: _telefoneController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileRootScreen()),
      );
    } on ClienteApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.bgPage,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.arrow_back, color: theme.textDark),
                      ),
                      Text(
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: theme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _campo(theme, label: 'Nome completo', controller: _nomeController),
                  const SizedBox(height: 14),
                  _campo(theme, label: 'CPF', controller: _cpfController, keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _campo(theme, label: 'Telefone', controller: _telefoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _campo(theme, label: 'Senha', controller: _senhaController, obscure: true),
                  const SizedBox(height: 14),
                  _campo(theme, label: 'Confirmar senha', controller: _confirmarSenhaController, obscure: true),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _criarConta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
                          : const Text(
                              'Criar conta',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: TextSpan(
                          text: 'Já tem conta? ',
                          style: TextStyle(color: theme.textMuted, fontSize: 13.5),
                          children: [
                            TextSpan(
                              text: 'Entrar',
                              style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _campo(
    ThemeProvider theme, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textDark),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: TextStyle(color: theme.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
