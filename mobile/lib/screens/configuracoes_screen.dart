import 'package:flutter/material.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/cliente_api.dart';
import '../services/google_auth.dart';
import '../utils/links.dart';
import 'login_screen.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  Future<void> _alternar(BuildContext context, {bool? push, bool? email, bool? biometrico}) async {
    final session = ClienteSessionScope.of(context);
    try {
      await session.atualizarPreferencias(notificacoesPush: push, notificacoesEmail: email, loginBiometrico: biometrico);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar a preferência.')));
    }
  }

  Future<void> _editarEmail(BuildContext context) async {
    final session = ClienteSessionScope.of(context);
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EmailDialog(session: session),
    );
    if (salvou == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('E-mail atualizado.')));
    }
  }

  Future<void> _excluirConta(BuildContext context) async {
    final session = ClienteSessionScope.of(context);
    final navigator = Navigator.of(context);
    final excluiu = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ExcluirContaDialog(session: session),
    );
    if (excluiu == true) {
      navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final session = ClienteSessionScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([theme, session]),
      builder: (context, child) {
        final pushEnabled = (session.cliente?['notificacoes_push'] as bool?) ?? true;
        final emailEnabled = (session.cliente?['notificacoes_email'] as bool?) ?? false;
        final biometricEnabled = (session.cliente?['login_biometrico'] as bool?) ?? false;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configurações', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
                  const SizedBox(height: 4),
                  Text('Preferências e segurança da sua conta', style: TextStyle(fontSize: 13, color: theme.textMuted)),
                  const SizedBox(height: 18),
                  _buildSection(
                    theme: theme,
                    title: 'Notificações',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Notificações push',
                        subtitle: 'Preferência salva — envio será ativado em breve',
                        icon: Icons.notifications_active_outlined,
                        value: pushEnabled,
                        onChanged: (v) => _alternar(context, push: v),
                      ),
                      _SwitchTile(
                        theme: theme,
                        title: 'E-mail marketing',
                        subtitle: 'Preferência salva — envio será ativado em breve',
                        icon: Icons.email_outlined,
                        value: emailEnabled,
                        onChanged: (v) => _alternar(context, email: v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Segurança',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Login biométrico',
                        subtitle: 'Preferência salva — será ativado em breve',
                        icon: Icons.fingerprint,
                        value: biometricEnabled,
                        onChanged: (v) => _alternar(context, biometrico: v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Aparência',
                    children: [
                      _SwitchTile(
                        theme: theme,
                        title: 'Modo escuro',
                        subtitle: 'Tema escuro do sistema',
                        icon: Icons.dark_mode_outlined,
                        value: theme.isDarkMode,
                        onChanged: (v) => theme.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Sobre',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.privacy_tip_outlined, color: theme.primary, size: 20),
                        ),
                        title: Text('Política de privacidade', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textDark)),
                        subtitle: Text('Como seus dados são usados', style: TextStyle(fontSize: 12, color: theme.textMuted)),
                        trailing: Icon(Icons.open_in_new, size: 18, color: theme.textMuted),
                        onTap: () => abrirPoliticaPrivacidade(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    theme: theme,
                    title: 'Conta',
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.alternate_email, color: theme.primary, size: 20),
                        ),
                        title: Text('E-mail de recuperação', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textDark)),
                        subtitle: Text(
                          (session.cliente?['email'] as String?)?.isNotEmpty == true
                              ? session.cliente!['email'] as String
                              : 'Adicione um e-mail para poder recuperar a senha',
                          style: TextStyle(fontSize: 12, color: theme.textMuted),
                        ),
                        trailing: Icon(Icons.edit_outlined, size: 18, color: theme.textMuted),
                        onTap: () => _editarEmail(context),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        ),
                        title: const Text('Excluir minha conta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                        subtitle: Text('Apaga seus dados e cartões definitivamente', style: TextStyle(fontSize: 12, color: theme.textMuted)),
                        onTap: () => _excluirConta(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text('Acumula Aí v1.0.0', style: TextStyle(fontSize: 12, color: theme.textHint))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({required ThemeProvider theme, required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: List.generate(children.length, (i) {
              return Column(
                children: [
                  children[i],
                  if (i != children.length - 1)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: theme.border)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final ThemeProvider theme;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.theme,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: theme.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textDark)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.textMuted)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: theme.primary,
      ),
    );
  }
}


class _ExcluirContaDialog extends StatefulWidget {
  final ClienteSession session;
  const _ExcluirContaDialog({required this.session});

  @override
  State<_ExcluirContaDialog> createState() => _ExcluirContaDialogState();
}

class _ExcluirContaDialogState extends State<_ExcluirContaDialog> {
  final _senhaController = TextEditingController();
  bool _excluindo = false;
  String? _erro;

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  bool get _contaGoogle => widget.session.cliente?['conta_google'] == true;

  /// Conta criada pelo Google não tem senha que o cliente conheça: a
  /// confirmação é escolher de novo a mesma conta Google.
  Future<void> _confirmarComGoogle() async {
    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      final idToken = await GoogleAuth.obterIdToken();
      if (idToken == null) {
        if (mounted) setState(() => _erro = 'Não foi possível obter a confirmação do Google.');
        return;
      }
      await widget.session.excluirConta(idToken: idToken);
      if (mounted) Navigator.of(context).pop(true);
    } on GoogleSignInException catch (e) {
      if (mounted && e.code != GoogleSignInExceptionCode.canceled) {
        setState(() => _erro = 'Não foi possível confirmar com o Google. Tente novamente.');
      }
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  Future<void> _confirmar() async {
    final senha = _senhaController.text;
    if (senha.isEmpty) {
      setState(() => _erro = 'Informe sua senha para confirmar.');
      return;
    }
    setState(() {
      _excluindo = true;
      _erro = null;
    });
    try {
      await widget.session.excluirConta(senha: senha);
      if (mounted) Navigator.of(context).pop(true);
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir conta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Esta ação é permanente: seus dados, cartões, marcações e resgates serão apagados e não poderão ser recuperados.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (_contaGoogle) ...[
            const Text(
              'Você entrou com o Google: confirme escolhendo a sua conta Google.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _excluindo ? null : _confirmarComGoogle,
                icon: const Icon(Icons.verified_user_outlined, size: 18),
                label: const Text('Confirmar com o Google'),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Ou, se você já definiu uma senha:', style: TextStyle(fontSize: 12.5)),
          ],
          TextField(
            controller: _senhaController,
            obscureText: true,
            enabled: !_excluindo,
            decoration: InputDecoration(labelText: 'Confirme sua senha', errorText: _erro),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _excluindo ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: _excluindo ? null : _confirmar,
          child: _excluindo
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Excluir', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}

class _EmailDialog extends StatefulWidget {
  final ClienteSession session;
  const _EmailDialog({required this.session});

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  late final TextEditingController _controller;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: (widget.session.cliente?['email'] as String?) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.session.atualizarEmail(_controller.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('E-mail de recuperação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usamos este e-mail só para enviar o código de recuperação de senha. Deixe em branco para remover.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            enabled: !_salvando,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'E-mail', errorText: _erro),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _salvando ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        TextButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
