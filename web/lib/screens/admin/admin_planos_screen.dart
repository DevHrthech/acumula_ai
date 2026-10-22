import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';

class AdminPlanosScreen extends StatefulWidget {
  final AdminSession session;
  const AdminPlanosScreen({super.key, required this.session});

  @override
  State<AdminPlanosScreen> createState() => _AdminPlanosScreenState();
}

class _AdminPlanosScreenState extends State<AdminPlanosScreen> {
  List<dynamic>? _planos;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final planos = await widget.session.api.listarPlanos();
      setState(() => _planos = planos);
    } on AdminApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar os planos.');
    }
  }

  Future<void> _novoPlano() async {
    final nomeController = TextEditingController();
    final valorController = TextEditingController();
    final descricaoController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminDialogShell(
        icone: Icons.add_card_outlined,
        titulo: 'Novo plano',
        subtitulo: 'Cadastre um novo plano de assinatura e defina suas regras comerciais.',
        conteudo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminField(label: 'Nome do plano *', controller: nomeController, placeholder: 'Ex: Plano Crescimento, Plano Gold ou Enterprise'),
            AdminField(
              label: 'Valor mensal (R\$) *',
              controller: valorController,
              teclado: const TextInputType.numberWithOptions(decimal: true),
              placeholder: '149,90',
            ),
            AdminField(
              label: 'Descrição do plano (opcional)',
              controller: descricaoController,
              maxLinhas: 3,
              placeholder: 'Ex: Ideal para franquias e lojas em expansão.',
            ),
          ],
        ),
        acoes: [
          AdminDialogActions.cancelar(context),
          AdminDialogActions.confirmar(context, 'Criar plano'),
        ],
      ),
    );

    if (confirmado != true) return;

    final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
    if (nomeController.text.trim().isEmpty || valor == null) {
      _erroSnack('Informe nome e valor válidos.');
      return;
    }

    try {
      await widget.session.api.criarPlano(
        nome: nomeController.text.trim(),
        valorMensal: valor,
        descricao: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano cadastrado.')));
      _carregar();
    } on AdminApiException catch (e) {
      _erroSnack(e.mensagem);
    }
  }

  Future<void> _editarPlano(Map<String, dynamic> plano) async {
    final nomeController = TextEditingController(text: plano['nome'] as String);
    final valorController = TextEditingController(text: '${plano['valor_mensal']}');
    final descricaoController = TextEditingController(text: plano['descricao'] as String? ?? '');
    bool ativo = plano['ativo'] != false;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AdminDialogShell(
          icone: Icons.edit_note_outlined,
          titulo: 'Editar plano',
          subtitulo: 'Modifique as condições, preço e limites deste plano de assinatura.',
          selo: AdminBadge(
            texto: '#PLN-${(plano['id'] as String).substring(0, 6).toUpperCase()}',
            cor: ThemeScope.of(context).primary,
            fundo: ThemeScope.of(context).primary.withValues(alpha: 0.1),
          ),
          conteudo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminField(label: 'Nome do plano *', controller: nomeController),
              AdminField(
                label: 'Valor mensal (R\$) *',
                controller: valorController,
                teclado: const TextInputType.numberWithOptions(decimal: true),
              ),
              AdminField(label: 'Descrição (opcional)', controller: descricaoController, maxLinhas: 3),
              const SizedBox(height: 4),
              _ToggleLinha(
                titulo: 'Status do plano',
                descricao: 'Planos ativos ficam visíveis para contratação imediata',
                valor: ativo,
                onChanged: (v) => setDialogState(() => ativo = v),
              ),
              const SizedBox(height: 12),
            ],
          ),
          acaoExtra: TextButton.icon(
            onPressed: () => setDialogState(() => ativo = false),
            icon: const Icon(Icons.block, size: 16, color: Colors.red),
            label: const Text('Desativar plano', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          acoes: [
            AdminDialogActions.cancelar(context),
            AdminDialogActions.confirmar(context, 'Salvar alterações', icone: Icons.save_outlined),
          ],
        ),
      ),
    );
    if (confirmado != true) return;

    final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
    if (nomeController.text.trim().isEmpty || valor == null) {
      _erroSnack('Informe nome e valor válidos.');
      return;
    }
    await _atualizar(
      plano['id'] as String,
      nome: nomeController.text.trim(),
      valorMensal: valor,
      descricao: descricaoController.text.trim(),
      ativo: ativo,
    );
  }

  Future<void> _atualizar(String id, {String? nome, double? valorMensal, String? descricao, bool? ativo}) async {
    try {
      await widget.session.api.atualizarPlano(id: id, nome: nome, valorMensal: valorMensal, descricao: descricao, ativo: ativo);
      _carregar();
    } on AdminApiException catch (e) {
      _erroSnack(e.mensagem);
    }
  }

  void _erroSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_planos == null && _erro == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null && _planos == null) {
      return Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)));
    }

    final planos = _planos!.cast<Map<String, dynamic>>();
    final ativos = planos.where((p) => p['ativo'] != false).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminPageHeader(
            titulo: 'Planos de Assinatura',
            contagem: planos.isEmpty ? null : '$ativos ativos',
            subtitulo: 'Configure os planos e precificação disponíveis para contratação pelos lojistas parceiros.',
            acoes: [
              AdminIconButton(icone: Icons.refresh, onPressed: _carregar, tooltip: 'Atualizar'),
              AdminFilledButton(icone: Icons.add, label: 'Novo plano', onPressed: _novoPlano),
            ],
          ),
          const SizedBox(height: 24),
          if (_erro != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Planos Habilitados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          if (planos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Nenhum plano cadastrado.', style: TextStyle(color: theme.textMuted))),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 18,
              children: planos.map((p) => _CardPlano(plano: p, onEditar: () => _editarPlano(p), onToggleAtivo: (v) => _atualizar(p['id'] as String, ativo: v))).toList(),
            ),
        ],
      ),
    );
  }
}

class _CardPlano extends StatelessWidget {
  final Map<String, dynamic> plano;
  final VoidCallback onEditar;
  final ValueChanged<bool> onToggleAtivo;

  const _CardPlano({required this.plano, required this.onEditar, required this.onToggleAtivo});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final ativo = plano['ativo'] != false;
    final descricao = plano['descricao'] as String?;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plano['nome'] as String,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ativo ? theme.textDark : theme.textMuted),
                ),
              ),
              Switch(value: ativo, onChanged: onToggleAtivo),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('R\$ ${formatarMoeda(num.tryParse('${plano['valor_mensal']}') ?? 0)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primary)),
              const SizedBox(width: 4),
              Text('/mês', style: TextStyle(fontSize: 13, color: theme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descricao != null && descricao.isNotEmpty ? descricao : 'Sem descrição cadastrada.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: descricao != null && descricao.isNotEmpty ? theme.textMuted : theme.textHint,
              fontStyle: descricao != null && descricao.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 18),
          Divider(height: 1, color: theme.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!ativo)
                Text('Desativado', style: TextStyle(fontSize: 12, color: theme.textMuted, fontWeight: FontWeight.w600))
              else
                const SizedBox.shrink(),
              OutlinedButton.icon(
                onPressed: onEditar,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primary,
                  side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleLinha extends StatelessWidget {
  final String titulo;
  final String descricao;
  final bool valor;
  final ValueChanged<bool> onChanged;

  const _ToggleLinha({required this.titulo, required this.descricao, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.inputBg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: theme.textDark)),
                const SizedBox(height: 2),
                Text(descricao, style: TextStyle(fontSize: 11.5, color: theme.textMuted)),
              ],
            ),
          ),
          Switch(value: valor, onChanged: onChanged),
        ],
      ),
    );
  }
}
