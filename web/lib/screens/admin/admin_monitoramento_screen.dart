import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';

class AdminMonitoramentoScreen extends StatefulWidget {
  final AdminSession session;
  const AdminMonitoramentoScreen({super.key, required this.session});

  @override
  State<AdminMonitoramentoScreen> createState() => _AdminMonitoramentoScreenState();
}

class _AdminMonitoramentoScreenState extends State<AdminMonitoramentoScreen> {
  Map<String, dynamic>? _resumo;
  List<dynamic>? _usoPorEmpresa;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final resumo = await widget.session.api.resumoMonitoramento();
      final uso = await widget.session.api.usoPorEmpresa();
      setState(() {
        _resumo = resumo;
        _usoPorEmpresa = uso;
      });
    } on AdminApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível carregar os dados de monitoramento.');
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
              Text('Monitoramento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textDark)),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
            ],
          ),
          const SizedBox(height: 16),
          if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
          if (_resumo == null && _erro == null) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_resumo != null)
            Expanded(
              child: ListView(
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _CardMetrica(theme: theme, titulo: 'Chamadas (24h)', valor: '${_resumo!['total24h']}'),
                      _CardMetrica(theme: theme, titulo: 'Chamadas (7d)', valor: '${_resumo!['total7d']}'),
                      _CardMetrica(theme: theme, titulo: 'Latência média', valor: '${_resumo!['latenciaMediaMs']} ms'),
                      _CardMetrica(
                        theme: theme,
                        titulo: 'Taxa de erro (24h)',
                        valor: _taxaErro(_resumo!['porClasseStatus'] as Map<String, dynamic>),
                        destaque: _temErro(_resumo!['porClasseStatus'] as Map<String, dynamic>),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('Endpoints mais chamados (24h)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
                  const SizedBox(height: 8),
                  ...(_resumo!['topRotas'] as List<dynamic>).map((r) {
                    final rota = r as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: _ChipMetodo(metodo: rota['metodo'] as String),
                        title: Text(rota['rota'] as String),
                        trailing: Text('${rota['total']}x', style: TextStyle(color: theme.textMuted)),
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                  Text('Uso por empresa (7d)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
                  const SizedBox(height: 8),
                  if (_usoPorEmpresa == null || _usoPorEmpresa!.isEmpty)
                    Text('Nenhuma chamada de empresa registrada ainda.', style: TextStyle(color: theme.textMuted)),
                  ...?_usoPorEmpresa?.map((u) {
                    final uso = u as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(uso['nome'] as String),
                        trailing: Text('${uso['totalChamadas']} chamadas', style: TextStyle(color: theme.primary, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _temErro(Map<String, dynamic> porClasseStatus) {
    return (porClasseStatus['4xx'] as int? ?? 0) > 0 || (porClasseStatus['5xx'] as int? ?? 0) > 0;
  }

  String _taxaErro(Map<String, dynamic> porClasseStatus) {
    final total = porClasseStatus.values.fold<int>(0, (soma, v) => soma + (v as int));
    if (total == 0) return '0%';
    final erros = (porClasseStatus['4xx'] as int? ?? 0) + (porClasseStatus['5xx'] as int? ?? 0);
    return '${((erros / total) * 100).toStringAsFixed(1)}%';
  }
}

class _CardMetrica extends StatelessWidget {
  final ThemeProvider theme;
  final String titulo;
  final String valor;
  final bool destaque;

  const _CardMetrica({required this.theme, required this.titulo, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: destaque ? Colors.red : theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: TextStyle(fontSize: 12, color: theme.textMuted)),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: destaque ? Colors.red : theme.textDark)),
        ],
      ),
    );
  }
}

class _ChipMetodo extends StatelessWidget {
  final String metodo;
  const _ChipMetodo({required this.metodo});

  Color get _cor {
    switch (metodo) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PATCH':
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: _cor, borderRadius: BorderRadius.circular(6)),
      child: Text(metodo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
