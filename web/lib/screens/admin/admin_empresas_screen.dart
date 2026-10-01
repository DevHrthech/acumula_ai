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
              IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
