import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../utils/admin_status.dart';
import '../../utils/baixar_arquivo.dart';
import '../../widgets/admin/admin_ui.dart';
import 'admin_empresa_detalhe_screen.dart';

class AdminEmpresasScreen extends StatefulWidget {
  final AdminSession session;
  const AdminEmpresasScreen({super.key, required this.session});

  @override
  State<AdminEmpresasScreen> createState() => _AdminEmpresasScreenState();
}

class _AdminEmpresasScreenState extends State<AdminEmpresasScreen> {
  List<dynamic>? _empresas;
  String? _erro;

  final _buscaController = TextEditingController();
  String _filtroStatus = 'TODOS';
  String _ordenacao = 'recentes';

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final empresas = await widget.session.api.listarEmpresas();
      setState(() => _empresas = empresas);
    } on AdminApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar as empresas.');
    }
  }

  Future<void> _novaEmpresa() async {
    final nome = TextEditingController();
    final cnpj = TextEditingController();
    final email = TextEditingController();
    final senha = TextEditingController();
    final recompensa = TextEditingController();
    final categoria = TextEditingController();
    final meta = TextEditingController(text: '10');
    String tipo = 'MARCACOES';
    String? matrizId;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AdminDialogShell(
          icone: Icons.add_business_outlined,
          titulo: 'Nova empresa',
          subtitulo:
              'Cadastre uma nova loja e configure sua campanha de fidelidade',
          largura: 640,
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminField(
                label: 'Nome da empresa *',
                controller: nome,
                placeholder: 'Ex: Barbearia Estilo LTDA',
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AdminField(
                      label: 'CNPJ *',
                      controller: cnpj,
                      placeholder: '00.000.000/0000-00',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AdminField(
                      label: 'E-mail de acesso *',
                      controller: email,
                      placeholder: 'contato@empresa.com.br',
                      teclado: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              AdminField(
                label: 'Senha inicial * (mín. 8 caracteres)',
                controller: senha,
                obscure: true,
                helper: 'Entregue à empresa; ela pode trocar depois.',
              ),
              AdminField(
                label: 'Categoria (opcional)',
                controller: categoria,
                placeholder: 'Ex: Barbearia, Restaurante...',
              ),
              AdminField(
                label: 'Recompensa *',
                controller: recompensa,
                placeholder: 'Ex: 1 Corte de Cabelo Grátis',
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AdminDropdown<String>(
                      label: 'Mecânica de fidelidade',
                      value: tipo,
                      helper: 'Fixa após o cadastro inicial',
                      items: const [
                        DropdownMenuItem(
                          value: 'MARCACOES',
                          child: Text(
                            'Marcações (Cartão Fidelidade)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'PONTOS',
                          child: Text('Pontos'),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => tipo = v!),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AdminField(
                      label: tipo == 'PONTOS'
                          ? 'Meta de pontos'
                          : 'Meta de marcações',
                      controller: meta,
                      teclado: TextInputType.number,
                      helper: 'Qtd. p/ resgate',
                    ),
                  ),
                ],
              ),
              AdminDropdown<String?>(
                label: 'Matriz (se for filial)',
                value: matrizId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— Nenhuma (esta empresa é matriz) —'),
                  ),
                  ...(_empresas ?? []).map(
                    (e) => DropdownMenuItem<String?>(
                      value: (e as Map<String, dynamic>)['id'] as String,
                      child: Text(
                        e['nome'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setDialogState(() => matrizId = v),
              ),
            ],
          ),
          acoes: [
            AdminDialogActions.cancelar(context),
            AdminDialogActions.confirmar(context, 'Cadastrar'),
          ],
        ),
      ),
    );
    if (confirmado != true) return;

    void erro(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }

    final metaNum = int.tryParse(meta.text.trim());
    if (nome.text.trim().isEmpty ||
        cnpj.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        senha.text.isEmpty ||
        recompensa.text.trim().isEmpty) {
      erro('Preencha nome, CNPJ, e-mail, senha e recompensa.');
      return;
    }
    if (metaNum == null) {
      erro('A meta deve ser um número inteiro.');
      return;
    }

    try {
      await widget.session.api.criarEmpresa(
        nome: nome.text.trim(),
        cnpj: cnpj.text.trim(),
        email: email.text.trim(),
        senha: senha.text,
        descricaoRecompensa: recompensa.text.trim(),
        categoria: categoria.text.trim().isEmpty ? null : categoria.text.trim(),
        tipoFidelidade: tipo,
        metaFidelidade: metaNum,
        empresaPaiId: matrizId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Empresa cadastrada.')));
      _carregar();
    } on AdminApiException catch (e) {
      erro(e.mensagem);
    } catch (_) {
      erro('Não foi possível cadastrar a empresa.');
    }
  }

  void _exportarCsv() {
    final linhas = <String>['Nome;CNPJ;Email;Codigo;Status'];
    for (final e in _listaFiltrada) {
      linhas.add(
        '${e['nome']};${e['cnpj']};${e['email']};${e['codigo_loja']};${e['licenca_status'] ?? 'SEM_LICENCA'}',
      );
    }
    final csv = linhas.join('\n');
    baixarArquivo(
      Uint8List.fromList(utf8.encode(csv)),
      'empresas.csv',
      'text/csv',
    );
  }

  List<Map<String, dynamic>> get _listaFiltrada {
    var lista = (_empresas ?? []).cast<Map<String, dynamic>>().toList();

    final busca = _buscaController.text.trim().toLowerCase();
    if (busca.isNotEmpty) {
      lista = lista.where((e) {
        final nome = (e['nome'] as String? ?? '').toLowerCase();
        final cnpj = (e['cnpj'] as String? ?? '').toLowerCase();
        final codigo = (e['codigo_loja'] as String? ?? '').toLowerCase();
        return nome.contains(busca) ||
            cnpj.contains(busca) ||
            codigo.contains(busca);
      }).toList();
    }

    if (_filtroStatus != 'TODOS') {
      lista = lista.where((e) {
        final status = e['licenca_status'] as String?;
        if (_filtroStatus == 'SEM_LICENCA') return status == null;
        return status == _filtroStatus;
      }).toList();
    }

    if (_ordenacao == 'nome') {
      lista.sort(
        (a, b) => (a['nome'] as String).toLowerCase().compareTo(
          (b['nome'] as String).toLowerCase(),
        ),
      );
    }
    // 'recentes' é a ordem que já vem da API (created_at desc).

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_empresas == null && _erro == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null && _empresas == null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: Colors.red)),
      );
    }

    final todas = _empresas!.cast<Map<String, dynamic>>();
    final total = todas.length;
    final ativas = todas.where((e) => e['licenca_status'] == 'ATIVA').length;
    final semLicenca = todas.where((e) => e['licenca_status'] == null).length;
    final inadimplentes = todas
        .where((e) => e['licenca_status'] == 'INADIMPLENTE')
        .length;
    final pctAtivas = total == 0
        ? '0%'
        : '${(ativas / total * 100).toStringAsFixed(1)}% da base';

    final lista = _listaFiltrada;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            titulo: 'Empresas',
            contagem: '${formatarMilhar(total)} cadastradas',
            subtitulo:
                'Gestão centralizada de lojas parceiras, licenças ativas e pontos de fidelidade.',
            acoes: [
              AdminIconButton(
                icone: Icons.refresh,
                onPressed: _carregar,
                tooltip: 'Atualizar',
              ),
              AdminOutlineButton(
                icone: Icons.download_outlined,
                label: 'Exportar CSV',
                onPressed: total == 0 ? null : _exportarCsv,
              ),
              AdminFilledButton(
                icone: Icons.add,
                label: 'Nova empresa',
                onPressed: _novaEmpresa,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(
                titulo: 'TOTAL DE EMPRESAS',
                valor: formatarMilhar(total),
                icone: Icons.store_outlined,
                corIcone: theme.primary,
              ),
              AdminStatCard(
                titulo: 'ATIVAS / REGULARES',
                valor: formatarMilhar(ativas),
                icone: Icons.verified_outlined,
                corIcone: theme.success,
                legenda: pctAtivas,
                corLegenda: theme.success,
              ),
              AdminStatCard(
                titulo: 'SEM LICENÇA',
                valor: formatarMilhar(semLicenca),
                icone: Icons.block_outlined,
                corIcone: theme.textMuted,
                legenda: semLicenca > 0 ? 'Requer ativação' : null,
              ),
              AdminStatCard(
                titulo: 'INADIMPLENTES',
                valor: formatarMilhar(inadimplentes),
                icone: Icons.warning_amber_outlined,
                corIcone: theme.warning,
                legenda: inadimplentes > 0 ? 'Atenção financeira' : null,
                corLegenda: theme.warning,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por razão social, CNPJ ou código',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filtroStatus,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.filter_list, size: 18),
                items: const [
                  DropdownMenuItem(
                    value: 'TODOS',
                    child: Text('Todos os status'),
                  ),
                  DropdownMenuItem(value: 'ATIVA', child: Text('Ativa')),
                  DropdownMenuItem(
                    value: 'INADIMPLENTE',
                    child: Text('Inadimplente'),
                  ),
                  DropdownMenuItem(
                    value: 'SEM_LICENCA',
                    child: Text('Sem licença'),
                  ),
                  DropdownMenuItem(
                    value: 'BLOQUEADA',
                    child: Text('Bloqueada'),
                  ),
                  DropdownMenuItem(
                    value: 'CANCELADA',
                    child: Text('Cancelada'),
                  ),
                ],
                onChanged: (v) => setState(() => _filtroStatus = v!),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _ordenacao,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.swap_vert, size: 18),
                items: const [
                  DropdownMenuItem(
                    value: 'recentes',
                    child: Text('Mais recentes'),
                  ),
                  DropdownMenuItem(value: 'nome', child: Text('Nome (A-Z)')),
                ],
                onChanged: (v) => setState(() => _ordenacao = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_erro!, style: const TextStyle(color: Colors.red)),
            ),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  todas.isEmpty
                      ? 'Nenhuma empresa cadastrada.'
                      : 'Nenhuma empresa encontrada para esse filtro.',
                  style: TextStyle(color: theme.textMuted),
                ),
              ),
            )
          else
            ...lista.map(
              (e) => _LinhaEmpresa(
                empresa: e,
                onTap: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => AdminEmpresaDetalheScreen(
                          session: widget.session,
                          empresaId: e['id'] as String,
                        ),
                      ),
                    )
                    .then((_) => _carregar()),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaEmpresa extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback onTap;

  const _LinhaEmpresa({required this.empresa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final status = empresa['licenca_status'] as String?;
    final apresentacao = apresentarStatusLicenca(theme, status);
    final nome = empresa['nome'] as String;

    final (acaoLabel, acaoIcone) = switch (status) {
      null => ('Gerar Licença', Icons.vpn_key_outlined),
      'INADIMPLENTE' => ('Gerir Licença', Icons.credit_card_outlined),
      'BLOQUEADA' || 'CANCELADA' => ('Reativar', Icons.autorenew),
      _ => ('Editar', Icons.edit_outlined),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                AdminAvatar(nome: nome, tamanho: 46),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: theme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            'CNPJ: ${empresa['cnpj']}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: theme.textMuted,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.inputBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              empresa['codigo_loja'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textDark,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 13,
                            color: theme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              empresa['email'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdminBadge(
                      texto: apresentacao.texto.toUpperCase(),
                      cor: apresentacao.cor,
                      fundo: apresentacao.fundo,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(acaoIcone, size: 14, color: theme.primary),
                        const SizedBox(width: 4),
                        Text(
                          acaoLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: theme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
