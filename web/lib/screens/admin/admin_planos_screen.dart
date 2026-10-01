import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Novo plano'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeController, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal (R\$)'),
            ),
            TextField(controller: descricaoController, decoration: const InputDecoration(labelText: 'Descrição (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Criar')),
        ],
      ),
    );

    if (confirmado != true) return;

    final valor = double.tryParse(valorController.text.replaceAll(',', '.'));
    if (nomeController.text.trim().isEmpty || valor == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe nome e valor válidos.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await widget.session.api.criarPlano(
        nome: nomeController.text.trim(),
        valorMensal: valor,
        descricao: descricaoController.text.trim().isEmpty ? null : descricaoController.text.trim(),
      );
      _carregar();
    } on AdminApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red));
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
              Text('Planos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textDark)),
              ElevatedButton.icon(onPressed: _novoPlano, icon: const Icon(Icons.add), label: const Text('Novo plano')),
            ],
          ),
          const SizedBox(height: 16),
          if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
          if (_planos == null && _erro == null) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_planos != null)
            Expanded(
              child: _planos!.isEmpty
                  ? Center(child: Text('Nenhum plano cadastrado.', style: TextStyle(color: theme.textMuted)))
                  : ListView.separated(
                      itemCount: _planos!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final p = _planos![i] as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            title: Text(p['nome'] as String),
                            subtitle: Text(p['descricao'] as String? ?? ''),
                            trailing: Text('R\$ ${p['valor_mensal']}/mês', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
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
