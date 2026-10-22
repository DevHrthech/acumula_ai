import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';

/// Gestão de usuários do painel interno 2RL (quem acessa `admin.acumulaai.com.br`
/// — hoje só o próprio admin logado; aqui será possível convidar/desativar
/// outras pessoas da equipe). AINDA NÃO HÁ API para isso — o back-end só tem
/// `AdminInterno` (id/nome/email/senha_hash), sem campo de status. Esta tela
/// é só o visual, com uma lista local em memória (não persiste, não fala com
/// o servidor); criar/editar/desativar aqui só muda o estado da tela.
class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _Usuario {
  final String id;
  String nome;
  String email;
  bool ativo;
  final DateTime criadoEm;

  _Usuario({required this.id, required this.nome, required this.email, required this.ativo, required this.criadoEm});
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  int _proximoId = 4;

  final List<_Usuario> _usuarios = [
    _Usuario(id: '1', nome: 'Admin 2RL', email: 'admin@2rl.com.br', ativo: true, criadoEm: DateTime.now().subtract(const Duration(days: 180))),
    _Usuario(id: '2', nome: 'Mariana Costa', email: 'mariana@2rl.com.br', ativo: true, criadoEm: DateTime.now().subtract(const Duration(days: 42))),
    _Usuario(id: '3', nome: 'Carlos Prado', email: 'carlos@2rl.com.br', ativo: false, criadoEm: DateTime.now().subtract(const Duration(days: 10))),
  ];

  final _buscaController = TextEditingController();
  String _filtroStatus = 'TODOS';
  String _ordenacao = 'recentes';

  String _gerarId() => '${_proximoId++}';

  @override
  void initState() {
    super.initState();
    _buscaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _novoUsuario() async {
    final nome = TextEditingController();
    final email = TextEditingController();
    final senha = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminDialogShell(
        icone: Icons.person_add_alt_outlined,
        titulo: 'Novo usuário',
        subtitulo: 'Conceda acesso ao painel interno 2RL para outra pessoa da equipe.',
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminField(label: 'Nome *', controller: nome, placeholder: 'Ex: Mariana Costa'),
            AdminField(
              label: 'E-mail de acesso *',
              controller: email,
              teclado: TextInputType.emailAddress,
              placeholder: 'nome@2rl.com.br',
            ),
            AdminField(
              label: 'Senha inicial * (mín. 8 caracteres)',
              controller: senha,
              obscure: true,
              helper: 'Entregue à pessoa; ela pode trocar depois.',
            ),
          ],
        ),
        acoes: [
          AdminDialogActions.cancelar(context),
          AdminDialogActions.confirmar(context, 'Cadastrar'),
        ],
      ),
    );
    if (confirmado != true) return;

    if (nome.text.trim().isEmpty || email.text.trim().isEmpty || senha.text.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, e-mail e uma senha com pelo menos 8 caracteres.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _usuarios.insert(0, _Usuario(id: _gerarId(), nome: nome.text.trim(), email: email.text.trim(), ativo: true, criadoEm: DateTime.now()));
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuário cadastrado (visual — ainda sem API; nada foi salvo no servidor).')),
    );
  }

  Future<void> _editarUsuario(_Usuario usuario) async {
    final nome = TextEditingController(text: usuario.nome);
    final email = TextEditingController(text: usuario.email);

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminDialogShell(
        icone: Icons.edit_outlined,
        titulo: 'Editar usuário',
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminField(label: 'Nome', controller: nome),
            AdminField(label: 'E-mail de acesso', controller: email, teclado: TextInputType.emailAddress),
          ],
        ),
        acoes: [
          AdminDialogActions.cancelar(context),
          AdminDialogActions.confirmar(context, 'Salvar'),
        ],
      ),
    );
    if (confirmado != true) return;
    if (nome.text.trim().isEmpty || email.text.trim().isEmpty) return;

    setState(() {
      usuario.nome = nome.text.trim();
      usuario.email = email.text.trim();
    });
  }

  void _alternarStatus(_Usuario usuario) {
    setState(() => usuario.ativo = !usuario.ativo);
  }

  List<_Usuario> get _listaFiltrada {
    var lista = List<_Usuario>.from(_usuarios);

    final busca = _buscaController.text.trim().toLowerCase();
    if (busca.isNotEmpty) {
      lista = lista.where((u) => u.nome.toLowerCase().contains(busca) || u.email.toLowerCase().contains(busca)).toList();
    }

    if (_filtroStatus != 'TODOS') {
      final ativo = _filtroStatus == 'ATIVO';
      lista = lista.where((u) => u.ativo == ativo).toList();
    }

    if (_ordenacao == 'nome') {
      lista.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    } else {
      lista.sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    }

    return lista;
  }

  String _formatarData(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    final total = _usuarios.length;
    final ativos = _usuarios.where((u) => u.ativo).length;
    final desativados = _usuarios.where((u) => !u.ativo).length;
    final novos30d = _usuarios.where((u) => DateTime.now().difference(u.criadoEm).inDays <= 30).length;

    final lista = _listaFiltrada;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            titulo: 'Usuários',
            contagem: '${formatarMilhar(total)} cadastrados',
            subtitulo: 'Gestão de acessos ao painel interno 2RL — convide ou desative pessoas da equipe.',
            acoes: [
              AdminFilledButton(icone: Icons.person_add_alt_1_outlined, label: 'Novo usuário', onPressed: _novoUsuario),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(titulo: 'TOTAL DE USUÁRIOS', valor: formatarMilhar(total), icone: Icons.people_alt_outlined, corIcone: theme.primary),
              AdminStatCard(
                titulo: 'ATIVOS',
                valor: formatarMilhar(ativos),
                icone: Icons.verified_outlined,
                corIcone: theme.success,
                legenda: total == 0 ? null : '${(ativos / total * 100).toStringAsFixed(1)}% da base',
                corLegenda: theme.success,
              ),
              AdminStatCard(
                titulo: 'DESATIVADOS',
                valor: formatarMilhar(desativados),
                icone: Icons.block_outlined,
                corIcone: theme.textMuted,
                legenda: desativados > 0 ? 'Sem acesso ao painel' : null,
              ),
              AdminStatCard(
                titulo: 'NOVOS (30 DIAS)',
                valor: formatarMilhar(novos30d),
                icone: Icons.person_add_alt_outlined,
                corIcone: theme.warning,
                legenda: novos30d > 0 ? 'Cadastrados recentemente' : null,
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
                    hintText: 'Buscar por nome ou e-mail',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: theme.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filtroStatus,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.filter_list, size: 18),
                items: const [
                  DropdownMenuItem(value: 'TODOS', child: Text('Todos os status')),
                  DropdownMenuItem(value: 'ATIVO', child: Text('Ativos')),
                  DropdownMenuItem(value: 'INATIVO', child: Text('Desativados')),
                ],
                onChanged: (v) => setState(() => _filtroStatus = v!),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _ordenacao,
                underline: const SizedBox.shrink(),
                icon: const Icon(Icons.swap_vert, size: 18),
                items: const [
                  DropdownMenuItem(value: 'recentes', child: Text('Mais recentes')),
                  DropdownMenuItem(value: 'nome', child: Text('Nome (A-Z)')),
                ],
                onChanged: (v) => setState(() => _ordenacao = v!),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (lista.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  _usuarios.isEmpty ? 'Nenhum usuário cadastrado.' : 'Nenhum usuário encontrado para esse filtro.',
                  style: TextStyle(color: theme.textMuted),
                ),
              ),
            )
          else
            ...lista.map((u) => _LinhaUsuario(
                  usuario: u,
                  criadoEmFormatado: _formatarData(u.criadoEm),
                  onEditar: () => _editarUsuario(u),
                  onAlternarStatus: () => _alternarStatus(u),
                )),
        ],
      ),
    );
  }
}

class _LinhaUsuario extends StatelessWidget {
  final _Usuario usuario;
  final String criadoEmFormatado;
  final VoidCallback onEditar;
  final VoidCallback onAlternarStatus;

  const _LinhaUsuario({
    required this.usuario,
    required this.criadoEmFormatado,
    required this.onEditar,
    required this.onAlternarStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEditar,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.border)),
            child: Row(
              children: [
                AdminAvatar(nome: usuario.nome, tamanho: 46),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario.nome, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textDark)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mail_outline, size: 13, color: theme.textMuted),
                          const SizedBox(width: 4),
                          Flexible(child: Text(usuario.email, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: theme.textMuted))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Criado em $criadoEmFormatado', style: TextStyle(fontSize: 11.5, color: theme.textHint)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdminBadge(
                      texto: usuario.ativo ? 'ATIVO' : 'DESATIVADO',
                      cor: usuario.ativo ? theme.success : theme.textMuted,
                      fundo: usuario.ativo ? theme.successBg : theme.surface,
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: onAlternarStatus,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(usuario.ativo ? Icons.block_outlined : Icons.autorenew, size: 14, color: usuario.ativo ? theme.danger : theme.primary),
                          const SizedBox(width: 4),
                          Text(
                            usuario.ativo ? 'Desativar' : 'Reativar',
                            style: TextStyle(fontSize: 12.5, color: usuario.ativo ? theme.danger : theme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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
