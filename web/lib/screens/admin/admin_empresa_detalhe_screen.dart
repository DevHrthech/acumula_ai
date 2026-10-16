import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';

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
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova licença'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: planoId,
                decoration: const InputDecoration(labelText: 'Plano'),
                items: _planos
                    .map((p) => DropdownMenuItem<String>(value: p['id'] as String, child: Text(p['nome'] as String)))
                    .toList(),
                onChanged: (v) => setDialogState(() => planoId = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vencimento'),
                subtitle: Text('${vencimento.day}/${vencimento.month}/${vencimento.year}'),
                trailing: const Icon(Icons.calendar_today, size: 18),
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: vencimento,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (data != null) setDialogState(() => vencimento = data);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Criar')),
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
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Definir empresa-matriz'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<String?>(
              initialValue: selecionadoId,
              decoration: const InputDecoration(labelText: 'Empresa-matriz'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Nenhuma (empresa independente)')),
                ...opcoes.map((e) => DropdownMenuItem<String?>(
                      value: e['id'] as String,
                      child: Text(e['nome'] as String, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setDialogState(() => selecionadoId = v),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salvar')),
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
      builder: (context) => AlertDialog(
        title: const Text('Editar cadastro da empresa'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da empresa')),
                TextField(controller: cnpj, decoration: const InputDecoration(labelText: 'CNPJ')),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail de acesso'),
                ),
                TextField(controller: categoria, decoration: const InputDecoration(labelText: 'Categoria')),
                TextField(controller: recompensa, decoration: const InputDecoration(labelText: 'Recompensa')),
                TextField(
                  controller: meta,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: e['tipo_fidelidade'] == 'PONTOS' ? 'Meta de pontos' : 'Meta de marcações',
                    helperText: 'A mecânica (${e['tipo_fidelidade'] == 'PONTOS' ? 'pontos' : 'marcações'}) é fixa após o cadastro.',
                  ),
                ),
                TextField(
                  controller: novaSenha,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha de acesso (opcional)',
                    helperText: 'Deixe em branco para manter a atual. Mínimo 8 caracteres.',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salvar')),
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

  Color _corStatus(String? status) {
    switch (status) {
      case 'ATIVA':
      case 'ASSINADO':
        return Colors.green;
      case 'INADIMPLENTE':
      case 'AGUARDANDO_ASSINATURA':
        return Colors.orange;
      case 'BLOQUEADA':
      case 'CANCELADA':
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_erro != null) {
      return Scaffold(appBar: AppBar(title: const Text('Empresa')), body: Center(child: Text(_erro!)));
    }
    if (_empresa == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final licencas = (_empresa!['licencas'] as List<dynamic>? ?? []);
    final contratos = (_empresa!['contratos'] as List<dynamic>? ?? []);
    final ultimaLicenca = licencas.isNotEmpty ? licencas.first as Map<String, dynamic> : null;
    final empresaPai = _empresa!['empresa_pai'] as Map<String, dynamic>?;
    final filiais = (_empresa!['filiais'] as List<dynamic>? ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(_empresa!['nome'] as String)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cadastro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
              TextButton.icon(
                onPressed: _editarCadastro,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar cadastro'),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nome: ${_empresa!['nome']}'),
                  Text('CNPJ: ${_empresa!['cnpj']}'),
                  Text('E-mail de acesso: ${_empresa!['email']}'),
                  Text('Categoria: ${_empresa!['categoria'] ?? '—'}'),
                  Text('Código da loja: ${_empresa!['codigo_loja']}'),
                  Text(
                    'Mecânica: ${_empresa!['tipo_fidelidade'] == 'PONTOS' ? 'Pontos' : 'Marcações'}'
                    ' · Meta: ${_empresa!['meta_fidelidade']}',
                  ),
                  Text('Recompensa: ${_empresa!['descricao_recompensa'] ?? '—'}'),
                  Text('Cadastrada em: ${_formatarData(_empresa!['created_at'] as String?)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Matriz / Filiais', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
              TextButton.icon(
                onPressed: _salvandoMatriz ? null : _definirMatriz,
                icon: _salvandoMatriz
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.account_tree_outlined),
                label: const Text('Definir matriz'),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    empresaPai != null
                        ? 'Empresa-matriz: ${empresaPai['nome']}'
                        : 'Esta empresa não possui matriz — é independente ou é ela própria uma matriz.',
                    style: TextStyle(color: theme.textMuted),
                  ),
                  if (filiais.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Filiais (${filiais.length}):', style: TextStyle(color: theme.textDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...filiais.map((f) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('• ${(f as Map<String, dynamic>)['nome']}', style: TextStyle(color: theme.textMuted)),
                        )),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Licenças', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
              TextButton.icon(onPressed: _novaLicenca, icon: const Icon(Icons.add), label: const Text('Nova licença')),
            ],
          ),
          if (licencas.isEmpty) Text('Nenhuma licença atribuída.', style: TextStyle(color: theme.textMuted)),
          ...licencas.map((l) {
            final licenca = l as Map<String, dynamic>;
            final status = licenca['status_efetivo'] as String? ?? licenca['status'] as String;
            final vencimento = DateTime.parse(licenca['data_vencimento'] as String);
            return Card(
              child: ListTile(
                title: Text('Plano: ${licenca['plano']?['nome'] ?? licenca['plano_id']}'),
                subtitle: Text('Vencimento: ${vencimento.day}/${vencimento.month}/${vencimento.year}'),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: _corStatus(status)),
                    IconButton(
                      icon: const Icon(Icons.autorenew),
                      tooltip: 'Renovar',
                      onPressed: () => _renovarLicenca(licenca['id'] as String),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => _alterarStatusLicenca(licenca['id'] as String, v),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'BLOQUEADA', child: Text('Bloquear')),
                        PopupMenuItem(value: 'CANCELADA', child: Text('Cancelar')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contratos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
              TextButton.icon(
                onPressed: () => _novoContrato(ultimaLicenca?['id'] as String?),
                icon: const Icon(Icons.add),
                label: const Text('Novo contrato'),
              ),
            ],
          ),
          if (contratos.isEmpty) Text('Nenhum contrato registrado.', style: TextStyle(color: theme.textMuted)),
          ...contratos.map((c) {
            final contrato = c as Map<String, dynamic>;
            final status = contrato['status'] as String;
            return Card(
              child: ListTile(
                title: Text('Contrato #${(contrato['id'] as String).substring(0, 8)}'),
                subtitle: Text('Status: $status'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)), backgroundColor: _corStatus(status)),
                    PopupMenuButton<String>(
                      onSelected: (v) => _avancarContrato(contrato['id'] as String, v),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'AGUARDANDO_ASSINATURA', child: Text('Aguardando assinatura')),
                        PopupMenuItem(value: 'ASSINADO', child: Text('Marcar como assinado')),
                        PopupMenuItem(value: 'CANCELADO', child: Text('Cancelar')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
