import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/mascaras.dart';
import '../services/cliente_api.dart';
import '../theme/theme_provider.dart';

/// Recuperação de senha em dois passos: (1) CPF -> a API envia um código de
/// 6 dígitos ao e-mail cadastrado; (2) código + nova senha. Volta com `true`
/// quando a senha foi redefinida.
class RecuperarSenhaScreen extends StatefulWidget {
  final String cpfInicial;
  const RecuperarSenhaScreen({super.key, this.cpfInicial = ''});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  late final TextEditingController _cpfController;
  final _codigoController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  bool _codigoEnviado = false;
  bool _carregando = false;
  String? _erro;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _cpfController = TextEditingController(text: widget.cpfInicial);
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _codigoController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    FocusScope.of(context).unfocus();
    if (_cpfController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o seu CPF.');
      return;
    }
    if (!cpfValido(_cpfController.text)) {
      setState(() => _erro = 'CPF inválido. Confira os números.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final mensagem = await ClienteApi().esqueciSenha(_cpfController.text.trim());
      setState(() {
        _codigoEnviado = true;
        _aviso = mensagem;
      });
    } on ClienteApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (_) {
      setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _redefinir() async {
    FocusScope.of(context).unfocus();
    if (_codigoController.text.trim().length != 6) {
      setState(() => _erro = 'Digite o código de 6 dígitos que você recebeu por e-mail.');
      return;
    }
    if (_senhaController.text.length < 8) {
      setState(() => _erro = 'A senha deve ter ao menos 8 caracteres.');
      return;
    }
    if (_senhaController.text != _confirmarController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await ClienteApi().redefinirSenha(
        cpf: _cpfController.text.trim(),
        codigo: _codigoController.text.trim(),
        novaSenha: _senhaController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ClienteApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (_) {
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
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: Icon(Icons.arrow_back, color: theme.textDark),
                      ),
                      Text('Recuperar senha',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: theme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _codigoEnviado
                        ? 'Digite o código de 6 dígitos que enviamos para o seu e-mail e escolha uma nova senha.'
                        : 'Informe o seu CPF. Enviaremos um código de 6 dígitos para o e-mail cadastrado na sua conta.',
                    style: TextStyle(fontSize: 13.5, color: theme.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  _campo(theme, label: 'CPF', controller: _cpfController, keyboardType: TextInputType.number, formatters: [cpfFormatter], hint: '000.000.000-00', enabled: !_codigoEnviado),
                  if (_codigoEnviado) ...[
                    const SizedBox(height: 14),
                    _campo(theme, label: 'Código recebido por e-mail', controller: _codigoController, keyboardType: TextInputType.number, formatters: soDigitos(6), hint: '000000'),
                    const SizedBox(height: 14),
                    _campo(theme, label: 'Nova senha', controller: _senhaController, obscure: true),
                    const SizedBox(height: 14),
                    _campo(theme, label: 'Confirmar nova senha', controller: _confirmarController, obscure: true),
                  ],
                  if (_aviso != null && _codigoEnviado) ...[
                    const SizedBox(height: 14),
                    Text(_aviso!, style: TextStyle(fontSize: 12.5, color: theme.textMuted, height: 1.4)),
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
                      onPressed: _carregando ? null : (_codigoEnviado ? _redefinir : _enviarCodigo),
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
                          : Text(
                              _codigoEnviado ? 'Redefinir senha' : 'Enviar código',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  if (_codigoEnviado) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _carregando ? null : _enviarCodigo,
                        child: Text('Reenviar código', style: TextStyle(color: theme.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Não cadastrou um e-mail? Fale com a gente em privacidade@acumulaai.com.br.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.textHint),
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
    List<TextInputFormatter>? formatters,
    String? hint,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscure = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textDark)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          textCapitalization: capitalization,
          obscureText: obscure,
          enabled: enabled,
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
