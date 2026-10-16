import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/mascaras.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'mobile_root_screen.dart';

/// Primeiro acesso com Google: o sistema precisa de CPF e telefone, que o
/// Google não fornece. Nome e e-mail já vêm da conta Google.
class CompletarGoogleScreen extends StatefulWidget {
  final String nome;
  final String email;
  final String tokenCadastro;

  const CompletarGoogleScreen({
    super.key,
    required this.nome,
    required this.email,
    required this.tokenCadastro,
  });

  @override
  State<CompletarGoogleScreen> createState() => _CompletarGoogleScreenState();
}

class _CompletarGoogleScreenState extends State<CompletarGoogleScreen> {
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  // Vira true quando o CPF já tem conta: aí pedimos a senha dela pra vincular
  // o Google (sem isso qualquer um poderia assumir uma conta alheia).
  bool _pedirSenha = false;
  String? _erro;

  @override
  void dispose() {
    _cpfController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _concluir() async {
    FocusScope.of(context).unfocus();
    if (_cpfController.text.trim().isEmpty || _telefoneController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o CPF e o telefone.');
      return;
    }
    if (!cpfValido(_cpfController.text)) {
      setState(() => _erro = 'CPF inválido. Confira os números.');
      return;
    }
    if (!telefoneValido(_telefoneController.text)) {
      setState(() => _erro = 'Telefone inválido. Informe o DDD e o número.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ClienteSessionScope.of(context).completarGoogle(
        tokenCadastro: widget.tokenCadastro,
        cpf: _cpfController.text.trim(),
        telefone: _telefoneController.text.trim(),
        senha: _pedirSenha ? _senhaController.text : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileRootScreen()),
        (route) => false,
      );
    } on ClienteApiException catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.mensagem;
          if (e.codigo == 'CPF_EXISTENTE') _pedirSenha = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível conectar à API.');
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
                      Text('Concluir cadastro',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: theme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Conta Google', style: TextStyle(fontSize: 12, color: theme.textMuted)),
                        const SizedBox(height: 4),
                        Text(widget.nome, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
                        Text(widget.email, style: TextStyle(fontSize: 13, color: theme.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Falta pouco! Precisamos do seu CPF e telefone para que as lojas identifiquem suas compras.',
                    style: TextStyle(fontSize: 13.5, color: theme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _campo(theme, label: 'CPF', controller: _cpfController, keyboardType: TextInputType.number, formatters: [cpfFormatter], hint: '000.000.000-00'),
                  const SizedBox(height: 14),
                  _campo(theme, label: 'Telefone', controller: _telefoneController, keyboardType: TextInputType.phone, formatters: [telefoneFormatter], hint: '(00) 00000-0000'),
                  if (_pedirSenha) ...[
                    const SizedBox(height: 14),
                    _campo(theme, label: 'Senha da sua conta (para vincular o Google)', controller: _senhaController, obscure: true),
                  ],
                  if (_erro != null) ...[
                    const SizedBox(height: 14),
                    Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _concluir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          : const Text('Concluir cadastro', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
    List<TextInputFormatter>? formatters,
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          inputFormatters: formatters,
          textCapitalization: capitalization,
          style: TextStyle(color: theme.textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textHint),
            filled: true,
            fillColor: theme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
