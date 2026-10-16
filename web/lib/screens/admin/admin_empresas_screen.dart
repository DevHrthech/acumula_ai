import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _carregar();
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
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nova empresa'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da empresa *')),
                  TextField(controller: cnpj, decoration: const InputDecoration(labelText: 'CNPJ *')),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail de acesso *'),
                  ),
                  TextField(
                    controller: senha,
                    decoration: const InputDecoration(
                      labelText: 'Senha inicial * (mín. 8 caracteres)',
                      helperText: 'Entregue à empresa; ela pode trocar depois.',
                    ),
                  ),
                  TextField(controller: categoria, decoration: const InputDecoration(labelText: 'Categoria (opcional)')),
                  TextField(
                    controller: recompensa,
                    decoration: const InputDecoration(labelText: 'Recompensa * (ex: 1 café grátis)'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: tipo,
                    decoration: const InputDecoration(labelText: 'Mecânica de fidelidade (fixa após o cadastro)'),
                    items: const [
                      DropdownMenuItem(value: 'MARCACOES', child: Text('Marcações')),
                      DropdownMenuItem(value: 'PONTOS', child: Text('Pontos')),
                    ],
                    onChanged: (v) => setDialogState(() => tipo = v!),
                  ),
                  TextField(
                    controller: meta,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tipo == 'PONTOS' ? 'Meta de pontos' : 'Meta de marcações'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: matrizId,
                    decoration: const InputDecoration(labelText: 'Matriz (se for filial)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('— Nenhuma —')),
                      ...(_empresas ?? []).map((e) => DropdownMenuItem<String?>(
                            value: (e as Map<String, dynamic>)['id'] as String,
                            child: Text(e['nome'] as String),
                          )),
                    ],
                    onChanged: (v) => setDialogState(() => matrizId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cadastrar')),
          ],
        ),
      ),
    );
    if (confirmado != true) return;

    void erro(String msg) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empresa cadastrada.')));
      _carregar();
    } on AdminApiException catch (e) {
      erro(e.mensagem);
    } catch (_) {
      erro('Não foi possível cadastrar a empresa.');
    }
  }

  Color _corStatus(String? status) {
    switch (status) {
      case 'ATIVA':
        return Colors.green;
      case 'INADIMPLENTE':
        return Colors.orange;
      case 'BLOQUEADA':
      case 'CANCELADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Empresas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textDark)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(onPressed: _novaEmpresa, icon: const Icon(Icons.add), label: const Text('Nova empresa')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
          if (_empresas == null && _erro == null) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_empresas != null)
            Expanded(
              child: _empresas!.isEmpty
                  ? Center(child: Text('Nenhuma empresa cadastrada.', style: TextStyle(color: theme.textMuted)))
                  : ListView.separated(
                      itemCount: _empresas!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = _empresas![i] as Map<String, dynamic>;
                        final status = e['licenca_status'] as String?;
                        return Card(
                          child: ListTile(
                            title: Text(e['nome'] as String),
                            subtitle: Text('CNPJ: ${e['cnpj']} · Código: ${e['codigo_loja']}'),
                            trailing: Chip(
                              label: Text(status ?? 'SEM LICENÇA', style: const TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: _corStatus(status),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminEmpresaDetalheScreen(session: widget.session, empresaId: e['id'] as String),
                              ),
                            ).then((_) => _carregar()),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
