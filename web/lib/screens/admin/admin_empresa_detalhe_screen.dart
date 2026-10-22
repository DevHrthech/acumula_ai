import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../utils/admin_status.dart';
import '../../widgets/admin/admin_ui.dart';

class AdminEmpresaDetalheScreen extends StatefulWidget {
  final AdminSession session;
  final String empresaId;
  const AdminEmpresaDetalheScreen({super.key, required this.session, required this.empresaId});

  @override
  State<AdminEmpresaDetalheScreen> createState() => _AdminEmpresaDetalheScreenState();
}

class _AdminEmpresaDetalheScreenState extends State<AdminEmpresaDetalheScreen> {
  Map<String, dynamic>? _empresa;
  List<dynamic> _planos = [];
  String? _erro;
  bool _salvandoMatriz = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final empresa = await widget.session.api.detalheEmpresa(widget.empresaId);
      final planos = await widget.session.api.listarPlanos();
      setState(() {
        _empresa = empresa;
        // Só planos ativos podem ser usados em novas licenças.
        _planos = planos.where((p) => (p as Map<String, dynamic>)['ativo'] != false).toList();
      });
    } on AdminApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar os dados da empresa.');
    }
  }

  Future<void> _mostrarErro(String msg) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _navegarParaEmpresa(String id) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AdminEmpresaDetalheScreen(session: widget.session, empresaId: id)));
    _carregar();
  }

  Future<void> _novaLicenca() async {
    if (_planos.isEmpty) {
      _mostrarErro('Cadastre um plano antes de criar uma licença.');
      return;
    }
    String planoId = _planos.first['id'] as String;
    DateTime vencimento = DateTime.now().add(const Duration(days: 30));

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AdminDialogShell(
          icone: Icons.vpn_key_outlined,
          titulo: 'Nova licença',
          subtitulo: 'Vincule um plano de assinatura e defina o vencimento.',
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminDropdown<String>(
                label: 'Plano',
                value: planoId,
                items: _planos.map((p) => DropdownMenuItem<String>(value: p['id'] as String, child: Text(p['nome'] as String))).toList(),
                onChanged: (v) => setDialogState(() => planoId = v!),
              ),
              _CampoData(
                label: 'Vencimento',
                data: vencimento,
                onSelecionar: (d) => setDialogState(() => vencimento = d),
              ),
            ],
          ),
          acoes: [
            AdminDialogActions.cancelar(context),
            AdminDialogActions.confirmar(context, 'Criar licença'),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    try {
      await widget.session.api.criarLicenca(
        empresaId: widget.empresaId,
        planoId: planoId,
        dataInicio: DateTime.now(),
        dataVencimento: vencimento,
      );
      _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  Future<void> _renovarLicenca(String licencaId) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (data == null) return;
    try {
      await widget.session.api.atualizarLicenca(licencaId: licencaId, dataVencimento: data, status: 'ATIVA');
      _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  Future<void> _alterarStatusLicenca(String licencaId, String status) async {
    try {
      await widget.session.api.atualizarLicenca(licencaId: licencaId, status: status);
      _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  Future<void> _novoContrato(String? licencaId) async {
    try {
      await widget.session.api.criarContrato(empresaId: widget.empresaId, licencaId: licencaId);
      _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  Future<void> _avancarContrato(String contratoId, String status) async {
    try {
      await widget.session.api.atualizarContrato(contratoId: contratoId, status: status);
      _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    }
  }

  Future<void> _definirMatriz() async {
    List<dynamic> empresas;
    try {
      empresas = await widget.session.api.listarEmpresas();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
      return;
    }
    if (!mounted) return;

    final opcoes = empresas.where((e) => e['id'] != widget.empresaId).toList();
    String? selecionadoId = _empresa!['empresa_pai']?['id'] as String?;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AdminDialogShell(
          icone: Icons.account_tree_outlined,
          titulo: 'Definir empresa-matriz',
          subtitulo: 'Agrupa esta empresa sob uma matriz para gestão comercial.',
          conteudo: AdminDropdown<String?>(
            label: 'Empresa-matriz',
            value: selecionadoId,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Nenhuma (empresa independente)')),
              ...opcoes.map((e) => DropdownMenuItem<String?>(
                    value: e['id'] as String,
                    child: Text(e['nome'] as String, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => setDialogState(() => selecionadoId = v),
          ),
          acoes: [
            AdminDialogActions.cancelar(context),
            AdminDialogActions.confirmar(context, 'Salvar'),
          ],
        ),
      ),
    );

    if (confirmado != true) return;

    setState(() => _salvandoMatriz = true);
    try {
      await widget.session.api.definirEmpresaPai(widget.empresaId, selecionadoId);
      await _carregar();
    } on AdminApiException catch (e) {
      _mostrarErro(e.mensagem);
    } finally {
      if (mounted) setState(() => _salvandoMatriz = false);
    }
  }

  String _formatarData(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _editarCadastro() async {
    final e = _empresa!;
    final nome = TextEditingController(text: e['nome'] as String);
    final cnpj = TextEditingController(text: e['cnpj'] as String);
    final email = TextEditingController(text: e['email'] as String);
    final categoria = TextEditingController(text: e['categoria'] as String? ?? '');
    final recompensa = TextEditingController(text: e['descricao_recompensa'] as String? ?? '');
    final meta = TextEditingController(text: '${e['meta_fidelidade']}');
    final novaSenha = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminDialogShell(
        icone: Icons.edit_outlined,
        titulo: 'Editar cadastro da empresa',
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminField(label: 'Nome da empresa', controller: nome),
            AdminField(label: 'CNPJ', controller: cnpj),
            AdminField(label: 'E-mail de acesso', controller: email, teclado: TextInputType.emailAddress),
            AdminField(label: 'Categoria', controller: categoria),
            AdminField(label: 'Recompensa', controller: recompensa),
            AdminField(
              label: e['tipo_fidelidade'] == 'PONTOS' ? 'Meta de pontos' : 'Meta de marcações',
              controller: meta,
              teclado: TextInputType.number,
              helper: 'A mecânica (${e['tipo_fidelidade'] == 'PONTOS' ? 'pontos' : 'marcações'}) é fixa após o cadastro.',
            ),
            AdminField(
              label: 'Nova senha de acesso (opcional)',
              controller: novaSenha,
              obscure: true,
              helper: 'Deixe em branco para manter a atual. Mínimo 8 caracteres.',
            ),
          ],
        ),
        acoes: [
          AdminDialogActions.cancelar(context),
          AdminDialogActions.confirmar(context, 'Salvar'),
        ],
      ),
    );
    if (confirmado != true) return;

    final metaNum = int.tryParse(meta.text.trim());
    if (metaNum == null) {
      _mostrarErro('A meta deve ser um número inteiro.');
      return;
    }

    // Só envia o que mudou.
    final campos = <String, dynamic>{};
    if (nome.text.trim() != e['nome']) campos['nome'] = nome.text.trim();
    if (cnpj.text.trim() != e['cnpj']) campos['cnpj'] = cnpj.text.trim();
    if (email.text.trim() != e['email']) campos['email'] = email.text.trim();
    if (categoria.text.trim() != (e['categoria'] as String? ?? '')) {
      campos['categoria'] = categoria.text.trim().isEmpty ? null : categoria.text.trim();
    }
    if (recompensa.text.trim() != (e['descricao_recompensa'] as String? ?? '')) {
      campos['descricaoRecompensa'] = recompensa.text.trim();
    }
    if (metaNum != e['meta_fidelidade']) campos['metaFidelidade'] = metaNum;
    if (novaSenha.text.isNotEmpty) campos['novaSenha'] = novaSenha.text;

    if (campos.isEmpty) return;

    try {
      await widget.session.api.atualizarEmpresa(widget.empresaId, campos);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastro atualizado.')));
      _carregar();
    } on AdminApiException catch (err) {
      _mostrarErro(err.mensagem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_erro != null && _empresa == null) {
      return Scaffold(
        backgroundColor: theme.bgPage,
        appBar: AppBar(title: const Text('Empresa')),
        body: Center(child: Text(_erro!)),
      );
    }
    if (_empresa == null) {
      return Scaffold(backgroundColor: theme.bgPage, body: const Center(child: CircularProgressIndicator()));
    }

    final e = _empresa!;
    final licencas = (e['licencas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final contratos = (e['contratos'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final ultimaLicenca = licencas.isNotEmpty ? licencas.first : null;
    final empresaPai = e['empresa_pai'] as Map<String, dynamic>?;
    final filiais = (e['filiais'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final nome = e['nome'] as String;
    final cnpj = e['cnpj'] as String;

    final statusGeral = apresentarStatusLicenca(theme, ultimaLicenca?['status_efetivo'] as String?);

    return Scaffold(
      backgroundColor: theme.bgPage,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Voltar para Empresas'),
                  style: TextButton.styleFrom(foregroundColor: theme.textDark),
                ),
                Text(' | ', style: TextStyle(color: theme.border)),
                Text('Empresas', style: TextStyle(color: theme.textMuted, fontSize: 13)),
                Text(' / ', style: TextStyle(color: theme.textMuted, fontSize: 13)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(nome, style: TextStyle(color: theme.textDark, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                ),
                const Spacer(),
                AdminOutlineButton(icone: Icons.sync, label: 'Sincronizar', onPressed: _carregar),
                const SizedBox(width: 10),
                AdminBadge(
                  texto: ultimaLicenca?['status_efetivo'] == 'ATIVA' ? 'ATIVA NO SISTEMA' : statusGeral.texto.toUpperCase(),
                  cor: statusGeral.cor,
                  fundo: statusGeral.fundo,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.border)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminAvatar(nome: nome, tamanho: 58),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(nome, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textDark))),
                            const SizedBox(width: 10),
                            AdminBadge(
                              texto: empresaPai != null ? 'Filial' : (filiais.isNotEmpty ? 'Matriz' : 'Independente'),
                              cor: theme.primary,
                              fundo: theme.primary.withValues(alpha: 0.1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            _MetaInfo(icone: Icons.calendar_today_outlined, texto: 'Cadastrada em ${_formatarData(e['created_at'] as String?)}'),
                            _MetaInfo(icone: Icons.mail_outline, texto: e['email'] as String),
                            _MetaInfo(icone: Icons.tag, texto: 'ID: #${(e['id'] as String).substring(0, 8).toUpperCase()}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AdminFilledButton(icone: Icons.edit_outlined, label: 'Editar Cadastro', onPressed: _editarCadastro),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AdminSectionCard(
              icone: Icons.badge_outlined,
              corIcone: theme.primary,
              titulo: 'Informações Cadastrais',
              subtitulo: 'Dados fundamentais e parâmetros de fidelização da loja',
              acao: AdminTextAction(icone: Icons.edit_outlined, label: 'Editar dados', onPressed: _editarCadastro),
              child: Wrap(
                spacing: 28,
                runSpacing: 18,
                children: [
                  _CampoInfo(label: 'RAZÃO SOCIAL / NOME', valor: nome),
                  _CampoInfo(
                    label: 'CNPJ',
                    valor: cnpj,
                    selo: AdminBadge(
                      texto: cnpjValido(cnpj) ? 'Válido' : 'Verificar',
                      cor: cnpjValido(cnpj) ? theme.success : theme.warning,
                      fundo: cnpjValido(cnpj) ? theme.successBg : theme.warningBg,
                    ),
                  ),
                  _CampoInfo(label: 'E-MAIL DE ACESSO', valor: e['email'] as String),
                  _CampoInfo(
                    label: 'CATEGORIA',
                    valor: e['categoria'] as String? ?? 'Não categorizada (—)',
                    italico: e['categoria'] == null,
                  ),
                  _CampoInfo(
                    label: 'CÓDIGO DA LOJA',
                    valor: e['codigo_loja'] as String,
                    monoChip: true,
                    acaoIcone: Icons.copy_outlined,
                    onAcao: () {
                      Clipboard.setData(ClipboardData(text: e['codigo_loja'] as String));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código copiado.')));
                    },
                  ),
                  _CampoInfo(
                    label: 'MECÂNICA DO PROGRAMA',
                    valorWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminBadge(
                          texto: e['tipo_fidelidade'] == 'PONTOS' ? 'Pontos' : 'Marcações',
                          cor: theme.primary,
                          fundo: theme.primary.withValues(alpha: 0.1),
                        ),
                        const SizedBox(width: 8),
                        Text('Meta: ${e['meta_fidelidade']}', style: TextStyle(color: theme.textDark, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  _CampoInfo(label: 'RECOMPENSA', valor: e['descricao_recompensa'] as String? ?? '—', icone: Icons.card_giftcard_outlined),
                  _CampoInfo(label: 'DATA DE CADASTRO', valor: _formatarData(e['created_at'] as String?)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AdminSectionCard(
              icone: Icons.account_tree_outlined,
              corIcone: theme.primary,
              titulo: 'Estrutura: Matriz & Filiais',
              subtitulo: 'Configuração de hierarquia e redes associadas',
              acao: _salvandoMatriz
                  ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : AdminTextAction(icone: Icons.add_link, label: 'Definir Matriz / Vincular Filiais', onPressed: _definirMatriz),
              child: (empresaPai == null && filiais.isEmpty)
                  ? const AdminEmptyState(
                      icone: Icons.store_mall_directory_outlined,
                      titulo: 'Unidade Independente',
                      descricao: 'Esta empresa não possui matriz vinculada — ela opera de forma independente ou atua como matriz principal.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (empresaPai != null)
                          _LinhaRelacionada(
                            titulo: 'Empresa-matriz',
                            nome: empresaPai['nome'] as String,
                            onTap: () => _navegarParaEmpresa(empresaPai['id'] as String),
                          ),
                        if (filiais.isNotEmpty) ...[
                          if (empresaPai != null) const SizedBox(height: 14),
                          Text('Filiais (${filiais.length})', style: TextStyle(color: theme.textDark, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 8),
                          ...filiais.map((f) => _LinhaRelacionada(
                                nome: f['nome'] as String,
                                onTap: () => _navegarParaEmpresa(f['id'] as String),
                              )),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final larguraEstreita = constraints.maxWidth < 760;
                final licencasCard = AdminSectionCard(
                  icone: Icons.vpn_key_outlined,
                  corIcone: theme.primary,
                  titulo: 'Licenças Ativas',
                  subtitulo: 'Acessos a terminais e instâncias',
                  acao: AdminTextAction(icone: Icons.add, label: 'Nova Licença', onPressed: _novaLicenca),
                  child: licencas.isEmpty
                      ? const AdminEmptyState(
                          icone: Icons.lock_outline,
                          titulo: 'Nenhuma licença atribuída',
                          descricao: 'Esta conta ainda não possui chaves de ativação ou terminais PDV vinculados.',
                        )
                      : Column(
                          children: licencas.map((l) => _LinhaLicenca(
                                licenca: l,
                                onRenovar: () => _renovarLicenca(l['id'] as String),
                                onStatus: (s) => _alterarStatusLicenca(l['id'] as String, s),
                              )).toList(),
                        ),
                );
                final contratosCard = AdminSectionCard(
                  icone: Icons.description_outlined,
                  corIcone: theme.primary,
                  titulo: 'Contratos & Faturamento',
                  subtitulo: 'Planos e acordos comerciais',
                  acao: AdminTextAction(icone: Icons.add, label: 'Novo Contrato', onPressed: () => _novoContrato(ultimaLicenca?['id'] as String?)),
                  child: contratos.isEmpty
                      ? const AdminEmptyState(
                          icone: Icons.note_add_outlined,
                          titulo: 'Nenhum contrato registrado',
                          descricao: 'Cadastre um contrato recorrente ou avulso para habilitar cobranças automáticas.',
                        )
                      : Column(
                          children: contratos.map((c) => _LinhaContrato(contrato: c, onAvancar: (s) => _avancarContrato(c['id'] as String, s))).toList(),
                        ),
                );

                if (larguraEstreita) {
                  return Column(children: [licencasCard, const SizedBox(height: 20), contratosCard]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: licencasCard),
                    const SizedBox(width: 20),
                    Expanded(child: contratosCard),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _MetaInfo({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 13, color: theme.textMuted),
        const SizedBox(width: 5),
        Text(texto, style: TextStyle(fontSize: 12.5, color: theme.textMuted)),
      ],
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String? valor;
  final Widget? valorWidget;
  final bool italico;
  final bool monoChip;
  final Widget? selo;
  final IconData? icone;
  final IconData? acaoIcone;
  final VoidCallback? onAcao;

  const _CampoInfo({
    required this.label,
    this.valor,
    this.valorWidget,
    this.italico = false,
    this.monoChip = false,
    this.selo,
    this.icone,
    this.acaoIcone,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.4)),
          const SizedBox(height: 6),
          if (valorWidget != null)
            valorWidget!
          else
            Row(
              children: [
                if (icone != null) ...[Icon(icone, size: 15, color: theme.textMuted), const SizedBox(width: 5)],
                if (monoChip)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: theme.inputBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(valor ?? '', style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: theme.textDark, fontSize: 13)),
                  )
                else
                  Flexible(
                    child: Text(
                      valor ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textDark,
                        fontStyle: italico ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ),
                if (selo != null) ...[const SizedBox(width: 8), selo!],
                if (acaoIcone != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: onAcao,
                      borderRadius: BorderRadius.circular(6),
                      child: Icon(acaoIcone, size: 15, color: theme.primary),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LinhaRelacionada extends StatelessWidget {
  final String? titulo;
  final String nome;
  final VoidCallback onTap;

  const _LinhaRelacionada({this.titulo, required this.nome, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Material(
      color: theme.bgPage,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AdminAvatar(nome: nome, tamanho: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (titulo != null) Text(titulo!, style: TextStyle(fontSize: 11, color: theme.textMuted)),
                    Text(nome, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textDark)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: theme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaLicenca extends StatelessWidget {
  final Map<String, dynamic> licenca;
  final VoidCallback onRenovar;
  final ValueChanged<String> onStatus;

  const _LinhaLicenca({required this.licenca, required this.onRenovar, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final status = licenca['status_efetivo'] as String? ?? licenca['status'] as String;
    final apresentacao = apresentarStatusLicenca(theme, status);
    final vencimento = DateTime.parse(licenca['data_vencimento'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.bgPage, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plano: ${licenca['plano']?['nome'] ?? licenca['plano_id']}', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textDark, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text('Vencimento: ${vencimento.day}/${vencimento.month}/${vencimento.year}', style: TextStyle(fontSize: 12, color: theme.textMuted)),
              ],
            ),
          ),
          AdminBadge(texto: apresentacao.texto.toUpperCase(), cor: apresentacao.cor, fundo: apresentacao.fundo),
          IconButton(icon: const Icon(Icons.autorenew, size: 18), tooltip: 'Renovar', onPressed: onRenovar),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: theme.textMuted),
            onSelected: onStatus,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'BLOQUEADA', child: Text('Bloquear')),
              PopupMenuItem(value: 'CANCELADA', child: Text('Cancelar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinhaContrato extends StatelessWidget {
  final Map<String, dynamic> contrato;
  final ValueChanged<String> onAvancar;

  const _LinhaContrato({required this.contrato, required this.onAvancar});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final status = contrato['status'] as String;
    final apresentacao = apresentarStatusContrato(theme, status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.bgPage, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.border)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Contrato #${(contrato['id'] as String).substring(0, 8)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.textDark, fontSize: 13.5),
            ),
          ),
          AdminBadge(texto: apresentacao.texto.toUpperCase(), cor: apresentacao.cor, fundo: apresentacao.fundo),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: theme.textMuted),
            onSelected: onAvancar,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'AGUARDANDO_ASSINATURA', child: Text('Aguardando assinatura')),
              PopupMenuItem(value: 'ASSINADO', child: Text('Marcar como assinado')),
              PopupMenuItem(value: 'CANCELADO', child: Text('Cancelar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampoData extends StatelessWidget {
  final String label;
  final DateTime data;
  final ValueChanged<DateTime> onSelecionar;

  const _CampoData({required this.label, required this.data, required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: data,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (d != null) onSelecionar(d);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(color: theme.inputBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.border)),
              child: Row(
                children: [
                  Expanded(child: Text('${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}', style: TextStyle(color: theme.textDark))),
                  Icon(Icons.calendar_today, size: 16, color: theme.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
