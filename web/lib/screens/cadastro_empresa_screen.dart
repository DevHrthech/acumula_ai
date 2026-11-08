import 'package:flutter/material.dart';
import '../services/empresa_api.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../theme/theme_provider.dart';
import 'web_root_screen.dart';

/// Auto-cadastro público da loja — acessível pelo botão "Criar conta" do
/// login. Mesmos campos do cadastro feito pelo admin 2RL (ver
/// AdminEmpresasScreen._novaEmpresa), exceto "Matriz" (vínculo entre
/// empresas é só gestão comercial interna, não faz sentido no auto-cadastro).
class CadastroEmpresaScreen extends StatefulWidget {
  const CadastroEmpresaScreen({super.key});

  @override
  State<CadastroEmpresaScreen> createState() => _CadastroEmpresaScreenState();
}

class _CadastroEmpresaScreenState extends State<CadastroEmpresaScreen> {
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _recompensaController = TextEditingController();
  final _metaController = TextEditingController(text: '10');
  String _tipoFidelidade = 'MARCACOES';
  bool _obscureSenha = true;
  bool _carregando = false;
  String? _erro;

  // Plano e forma de pagamento (cobrança via gateway Asaas, trial de 15 dias).
  List<Map<String, dynamic>> _planos = [];
  bool _carregandoPlanos = true;
  String? _planoId;
  String _formaPagamento = 'PIX';
  bool _aceiteTermos = false;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    try {
      final lista = await EmpresaApi().listarPlanosPublicos();
      if (!mounted) return;
      setState(() {
        _planos = lista.cast<Map<String, dynamic>>();
        _planoId = _planos.isNotEmpty ? _planos.first['id'] as String : null;
        _carregandoPlanos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoPlanos = false);
    }
  }

  /// `valor_mensal` chega como texto decimal ("99.90").
  String _valorBR(dynamic valor) {
    final v = double.tryParse('$valor') ?? 0;
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _categoriaController.dispose();
    _recompensaController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();

    if (_nomeController.text.trim().isEmpty ||
        _cnpjController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _senhaController.text.isEmpty ||
        _recompensaController.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha nome, CNPJ, e-mail, senha e recompensa.');
      return;
    }
    if (_senhaController.text.length < 8) {
      setState(() => _erro = 'A senha deve ter ao menos 8 caracteres.');
      return;
    }
    final meta = int.tryParse(_metaController.text.trim());
    if (meta == null) {
      setState(() => _erro = 'A meta deve ser um número inteiro.');
      return;
    }
    if (_planoId == null) {
      setState(() => _erro = 'Escolha um plano.');
      return;
    }
    if (!_aceiteTermos) {
      setState(() => _erro = 'Aceite que os pagamentos serão processados via gateway Asaas.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      await session.registrar(
        nome: _nomeController.text.trim(),
        cnpj: _cnpjController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        descricaoRecompensa: _recompensaController.text.trim(),
        categoria: _categoriaController.text.trim().isEmpty ? null : _categoriaController.text.trim(),
        tipoFidelidade: _tipoFidelidade,
        metaFidelidade: meta,
        planoId: _planoId!,
        formaPagamento: _formaPagamento,
        aceiteTermos: _aceiteTermos,
      );
      if (!mounted) return;
      EmpresaConfigScope.of(context).carregarDe(session.empresa!);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WebRootScreen()),
      );
    } on EmpresaApiException catch (e) {
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
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E), const Color(0xFF0F3460)]
                    : [const Color(0xFFE9D5F5), const Color(0xFFFCE7F3), const Color(0xFFFFF6E5)],
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
                        boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                      ),
                      child: Center(child: Icon(Icons.change_history, color: theme.accent, size: 56)),
                    ),
                    const SizedBox(height: 24),
                    Text('Acumula Aí', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.primary)),
                    const SizedBox(height: 8),
                    Text('Crie a conta da sua loja', style: TextStyle(fontSize: 15, color: theme.textMuted)),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Rotulo('Nome da empresa *', theme: theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nomeController,
                            decoration: _inputDecoration(theme, hint: 'Ex: Barbearia Estilo LTDA', prefixIcon: Icons.storefront_outlined),
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, c) {
                              final estreito = c.maxWidth < 420;
                              final cnpj = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Rotulo('CNPJ *', theme: theme),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _cnpjController,
                                    decoration: _inputDecoration(theme, hint: '00.000.000/0000-00', prefixIcon: Icons.badge_outlined),
                                  ),
                                ],
                              );
                              final email = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Rotulo('E-mail de acesso *', theme: theme),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: _inputDecoration(theme, hint: 'contato@suaempresa.com.br', prefixIcon: Icons.mail_outline),
                                  ),
                                ],
                              );
                              if (estreito) {
                                return Column(children: [cnpj, const SizedBox(height: 20), email]);
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Expanded(child: cnpj), const SizedBox(width: 16), Expanded(child: email)],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _Rotulo('Senha inicial * (mín. 8 caracteres)', theme: theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _senhaController,
                            obscureText: _obscureSenha,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: theme.textHint, fontSize: 18),
                              prefixIcon: Icon(Icons.lock_outline, color: theme.textHint),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: theme.textHint),
                                onPressed: () => setState(() => _obscureSenha = !_obscureSenha),
                              ),
                              filled: true,
                              fillColor: theme.surface,
                              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                              border: _outlineBorder(theme),
                              enabledBorder: _outlineBorder(theme),
                              focusedBorder: _outlineBorder(theme, color: theme.primary, width: 1.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _Rotulo('Categoria (opcional)', theme: theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoriaController,
                            decoration: _inputDecoration(theme, hint: 'Ex: Barbearia, Restaurante...', prefixIcon: Icons.category_outlined),
                          ),
                          const SizedBox(height: 20),
                          _Rotulo('Recompensa *', theme: theme),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _recompensaController,
                            decoration: _inputDecoration(theme, hint: 'Ex: 1 Corte de Cabelo Grátis', prefixIcon: Icons.card_giftcard_outlined),
                          ),
                          const SizedBox(height: 20),
                          LayoutBuilder(
                            builder: (context, c) {
                              final estreito = c.maxWidth < 420;
                              final mecanica = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Rotulo('Mecânica de fidelidade', theme: theme),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: _tipoFidelidade,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: theme.surface,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                      border: _outlineBorder(theme),
                                      enabledBorder: _outlineBorder(theme),
                                      focusedBorder: _outlineBorder(theme, color: theme.primary, width: 1.5),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'MARCACOES', child: Text('Marcações (Cartão Fidelidade)', overflow: TextOverflow.ellipsis)),
                                      DropdownMenuItem(value: 'PONTOS', child: Text('Pontos')),
                                    ],
                                    onChanged: (v) => setState(() => _tipoFidelidade = v!),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text('Fixa após o cadastro inicial', style: TextStyle(fontSize: 11.5, color: theme.textMuted)),
                                  ),
                                ],
                              );
                              final meta = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Rotulo(_tipoFidelidade == 'PONTOS' ? 'Meta de pontos' : 'Meta de marcações', theme: theme),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _metaController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration(theme, hint: '10', prefixIcon: Icons.flag_outlined),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Text('Qtd. p/ resgate', style: TextStyle(fontSize: 11.5, color: theme.textMuted)),
                                  ),
                                ],
                              );
                              if (estreito) {
                                return Column(children: [mecanica, const SizedBox(height: 20), meta]);
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Expanded(child: mecanica), const SizedBox(width: 16), Expanded(child: meta)],
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          Divider(color: theme.border),
                          const SizedBox(height: 16),
                          _Rotulo('Plano *', theme: theme),
                          const SizedBox(height: 8),
                          if (_carregandoPlanos)
                            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          else if (_planos.isEmpty)
                            Text('Nenhum plano disponível no momento. Tente novamente mais tarde.',
                                style: TextStyle(fontSize: 13, color: theme.textMuted))
                          else
                            DropdownButtonFormField<String>(
                              initialValue: _planoId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.surface,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                border: _outlineBorder(theme),
                                enabledBorder: _outlineBorder(theme),
                                focusedBorder: _outlineBorder(theme, color: theme.primary, width: 1.5),
                              ),
                              items: [
                                for (final p in _planos)
                                  DropdownMenuItem(
                                    value: p['id'] as String,
                                    child: Text('${p['nome']} — ${_valorBR(p['valor_mensal'])}/mês', overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _planoId = v),
                            ),
                          const SizedBox(height: 20),
                          _Rotulo('Forma de pagamento *', theme: theme),
                          const SizedBox(height: 8),
                          RadioGroup<String>(
                            groupValue: _formaPagamento,
                            onChanged: (v) => setState(() => _formaPagamento = v ?? _formaPagamento),
                            child: Column(
                              children: [
                                RadioListTile<String>(
                                  value: 'PIX',
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: theme.primary,
                                  title: Text('Pix', style: TextStyle(color: theme.textDark)),
                                ),
                                RadioListTile<String>(
                                  value: 'CARTAO_RECORRENTE',
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  activeColor: theme.primary,
                                  title: Text('Cartão de crédito recorrente', style: TextStyle(color: theme.textDark)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.card_giftcard_outlined, size: 20, color: theme.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Teste grátis por 15 dias, uma única vez por empresa. Nenhuma cobrança é feita agora; '
                                    'ao fim do período, a mensalidade do plano escolhido é cobrada pela forma de pagamento selecionada.',
                                    style: TextStyle(fontSize: 12.5, color: theme.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _aceiteTermos,
                            onChanged: (v) => setState(() => _aceiteTermos = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            activeColor: theme.primary,
                            title: Text(
                              'Estou ciente de que os pagamentos da mensalidade serão processados via gateway de pagamento Asaas '
                              '(Pix ou cartão de crédito recorrente), e autorizo o envio dos dados da minha empresa (nome, CNPJ e e-mail) ao Asaas para esse fim. *',
                              style: TextStyle(fontSize: 12.5, color: theme.textDark),
                            ),
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 16),
                            Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _cadastrar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primary,
                                foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                                elevation: 4,
                                shadowColor: theme.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              ),
                              child: _carregando
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Criar conta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Já tem uma conta? ', style: TextStyle(color: theme.textMuted, fontSize: 14)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Entrar', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: theme.textHint),
                        const SizedBox(width: 6),
                        Text('SEGURO', style: TextStyle(fontSize: 11, color: theme.textHint, letterSpacing: 1, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 18),
                        Icon(Icons.verified_outlined, size: 16, color: theme.textHint),
                        const SizedBox(width: 6),
                        Text('OFICIAL', style: TextStyle(fontSize: 11, color: theme.textHint, letterSpacing: 1, fontWeight: FontWeight.w500)),
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

class _Rotulo extends StatelessWidget {
  final String texto;
  final ThemeProvider theme;
  const _Rotulo(this.texto, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(texto, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textDark));
  }
}

OutlineInputBorder _outlineBorder(ThemeProvider theme, {Color? color, double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color ?? theme.border, width: width),
  );
}

InputDecoration _inputDecoration(ThemeProvider theme, {required String hint, required IconData prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: theme.textHint, fontSize: 15),
    prefixIcon: Icon(prefixIcon, color: theme.textHint),
    filled: true,
    fillColor: theme.surface,
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    border: _outlineBorder(theme),
    enabledBorder: _outlineBorder(theme),
    focusedBorder: _outlineBorder(theme, color: theme.primary, width: 1.5),
  );
}
