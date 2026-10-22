import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_recuperar_senha_screen.dart';
import 'admin_shell.dart';

class AdminLoginScreen extends StatefulWidget {
  final AdminSession session;
  const AdminLoginScreen({super.key, required this.session});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _lembrar = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await widget.session.login(_emailController.text.trim(), _senhaController.text, lembrar: _lembrar);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminShell(session: widget.session)),
      );
    } on AdminApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _irParaRecuperarSenha() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminRecuperarSenhaScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return AdminAuthScaffold(
      conteudoCard: Column(
        children: [
          const AdminAuthIcon(icone: Icons.admin_panel_settings_rounded),
          const SizedBox(height: 20),
          const AdminAuthPill(texto: 'Acesso Restrito / Admin'),
          const SizedBox(height: 16),
          Text('Painel Interno 2RL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 10),
          Text(
            'Gestão centralizada de empresas parceiras, contratos e licenciamento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: theme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 28),
          AdminAuthField(
            label: 'E-MAIL CORPORATIVO',
            controller: _emailController,
            teclado: TextInputType.emailAddress,
            placeholder: 'email@empresa.com.br',
            prefixIcon: Icon(Icons.mail_outline, size: 19, color: theme.textMuted),
            onSubmitted: (_) => _entrar(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SENHA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.5)),
              InkWell(
                onTap: _irParaRecuperarSenha,
                child: Text('Esqueceu a senha?', style: TextStyle(fontSize: 12.5, color: theme.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AdminAuthField(
            controller: _senhaController,
            obscure: !_mostrarSenha,
            prefixIcon: Icon(Icons.lock_outline, size: 19, color: theme.textMuted),
            suffixIcon: IconButton(
              icon: Icon(_mostrarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19, color: theme.textMuted),
              onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
            ),
            onSubmitted: (_) => _entrar(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: _lembrar,
                  onChanged: (v) => setState(() => _lembrar = v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Text('Lembrar acesso neste dispositivo', style: TextStyle(fontSize: 13, color: theme.textDark)),
            ],
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          AdminAuthButton(label: 'Entrar no Painel', carregando: _carregando, onPressed: _entrar),
          const SizedBox(height: 22),
          Divider(color: theme.border),
          const SizedBox(height: 14),
          const AdminAuthSeguranca(),
        ],
      ),
    );
  }
}
