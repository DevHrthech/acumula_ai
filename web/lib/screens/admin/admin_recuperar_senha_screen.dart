import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';

/// Tela de "esqueci minha senha" do painel admin. Não existe recuperação
/// self-service no back-end (só `/auth/admin/login`) — enviar o formulário
/// não dispara e-mail nenhum, só mostra uma orientação honesta pra contatar
/// o suporte de TI. Mantida como tela própria (visual igual ao login) porque
/// foi pedido explicitamente; o botão não finge uma chamada de API que não
/// existe.
class AdminRecuperarSenhaScreen extends StatefulWidget {
  const AdminRecuperarSenhaScreen({super.key});

  @override
  State<AdminRecuperarSenhaScreen> createState() => _AdminRecuperarSenhaScreenState();
}

class _AdminRecuperarSenhaScreenState extends State<AdminRecuperarSenhaScreen> {
  final _emailController = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _enviar() {
    final email = _emailController.text.trim();
    final valido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
    if (!valido) {
      setState(() => _erro = 'Informe um e-mail corporativo válido.');
      return;
    }
    setState(() => _erro = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação automática ainda não disponível — contate o suporte de TI da 2RL para redefinir sua senha.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return AdminAuthScaffold(
      conteudoCard: Column(
        children: [
          AdminAuthIcon(icone: Icons.lock_reset_rounded, iconeSelo: Icons.shield_outlined, corSelo: theme.accent),
          const SizedBox(height: 20),
          const AdminAuthPill(texto: 'Recuperação de Acesso / Segurança'),
          const SizedBox(height: 16),
          Text('Recuperar Senha', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 10),
          Text(
            'Informe seu e-mail corporativo cadastrado para receber as instruções e o link seguro de redefinição de acesso.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: theme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 28),
          AdminAuthField(
            label: 'E-MAIL CORPORATIVO CADASTRADO',
            controller: _emailController,
            teclado: TextInputType.emailAddress,
            placeholder: 'seu.email@2rl.com.br',
            prefixIcon: Icon(Icons.alternate_email, size: 19, color: theme.textMuted),
            onSubmitted: (_) => _enviar(),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.5, color: theme.textDark, height: 1.4),
                      children: const [
                        TextSpan(text: 'O link de recuperação possui validade de '),
                        TextSpan(text: '30 minutos', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' e só pode ser utilizado uma única vez por razões de conformidade e segurança institucional.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AdminAuthButton(label: 'Enviar Link de Recuperação', onPressed: _enviar),
          const SizedBox(height: 18),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: theme.textDark),
                const SizedBox(width: 8),
                Text('Voltar para o Login', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: theme.border),
          const SizedBox(height: 14),
          const AdminAuthSeguranca(),
        ],
      ),
    );
  }
}
