import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import '../../state/admin_session.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/admin/admin_ui.dart';

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

  bool _temErro(Map<String, dynamic> porClasseStatus) {
    return (porClasseStatus['4xx'] as int? ?? 0) > 0 || (porClasseStatus['5xx'] as int? ?? 0) > 0;
  }

  String _taxaErro(Map<String, dynamic> porClasseStatus) {
    final total = porClasseStatus.values.fold<int>(0, (soma, v) => soma + (v as int));
    if (total == 0) return '0%';
    final erros = (porClasseStatus['4xx'] as int? ?? 0) + (porClasseStatus['5xx'] as int? ?? 0);
    return '${((erros / total) * 100).toStringAsFixed(1)}%';
  }

  int _erros(Map<String, dynamic> porClasseStatus) =>
      (porClasseStatus['4xx'] as int? ?? 0) + (porClasseStatus['5xx'] as int? ?? 0);

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    if (_resumo == null && _erro == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null && _resumo == null) {
      return Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)));
    }

    final porClasseStatus = _resumo!['porClasseStatus'] as Map<String, dynamic>;
    final comErro = _temErro(porClasseStatus);
    final total24h = _resumo!['total24h'] as int;
    final total7d = _resumo!['total7d'] as int;
    final latencia = _resumo!['latenciaMediaMs'] as int;
    final latenciaOk = latencia < 300;
    final topRotas = (_resumo!['topRotas'] as List<dynamic>).cast<Map<String, dynamic>>();
    final maiorRota = topRotas.isEmpty ? 1 : topRotas.map((r) => r['total'] as int).reduce((a, b) => a > b ? a : b);
    final uso = (_usoPorEmpresa ?? []).cast<Map<String, dynamic>>();
    final maiorUso = uso.isEmpty ? 1 : uso.map((u) => u['totalChamadas'] as int).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Monitoramento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textDark)),
                    const SizedBox(width: 12),
                    AdminBadge(
                      texto: comErro ? 'Atenção necessária' : 'Sistemas Operacionais',
                      cor: comErro ? theme.danger : theme.success,
                      fundo: comErro ? theme.dangerBg : theme.successBg,
                    ),
                  ],
                ),
              ),
              AdminIconButton(icone: Icons.refresh, onPressed: _carregar, tooltip: 'Atualizar'),
            ],
          ),
          const SizedBox(height: 6),
          Text('Métricas de performance da API e consumo de endpoints', style: TextStyle(fontSize: 13, color: theme.textMuted)),
          const SizedBox(height: 24),
          if (_erro != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              AdminStatCard(titulo: 'CHAMADAS (24H)', valor: formatarMilhar(total24h), icone: Icons.bolt_outlined, corIcone: theme.primary),
              AdminStatCard(
                titulo: 'CHAMADAS (7D)',
                valor: formatarMilhar(total7d),
                icone: Icons.calendar_view_week_outlined,
                corIcone: theme.primary,
                legenda: 'Média de ${(total7d / 7).toStringAsFixed(0)} req/dia',
              ),
              AdminStatCard(
                titulo: 'LATÊNCIA MÉDIA',
                valor: '$latencia ms',
                icone: Icons.speed_outlined,
                corIcone: latenciaOk ? theme.success : theme.warning,
                legenda: latenciaOk ? 'Ótima · meta < 300 ms' : 'Acima da meta (< 300 ms)',
                corLegenda: latenciaOk ? theme.success : theme.warning,
              ),
              AdminStatCard(
                titulo: 'TAXA DE ERRO (24H)',
                valor: _taxaErro(porClasseStatus),
                icone: Icons.error_outline,
                corIcone: comErro ? theme.danger : theme.success,
                legenda: '${_erros(porClasseStatus)} erros / $total24h',
                corLegenda: comErro ? theme.danger : theme.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Endpoints mais chamados (24h)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 4),
          Text('Distribuição volumétrica das requisições atendidas pela API', style: TextStyle(fontSize: 12.5, color: theme.textMuted)),
          const SizedBox(height: 12),
          if (topRotas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma chamada registrada nas últimas 24h.', style: TextStyle(color: theme.textMuted)),
            )
          else
            ...topRotas.map((r) => _LinhaRota(rota: r, maior: maiorRota)),
          const SizedBox(height: 28),
          Text('Uso por empresa (7d)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 4),
          Text('Consumo total acumulado de requisições por cliente', style: TextStyle(fontSize: 12.5, color: theme.textMuted)),
          const SizedBox(height: 12),
          if (uso.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma chamada de empresa registrada ainda.', style: TextStyle(color: theme.textMuted)),
            )
          else
            ...uso.map((u) => _LinhaUsoEmpresa(uso: u, maior: maiorUso)),
        ],
      ),
    );
  }
}

class _LinhaRota extends StatelessWidget {
  final Map<String, dynamic> rota;
  final int maior;

  const _LinhaRota({required this.rota, required this.maior});

  Color _corMetodo(String metodo, ThemeProvider theme) {
    switch (metodo) {
      case 'GET':
        return theme.warning;
      case 'POST':
        return theme.success;
      case 'PATCH':
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return theme.danger;
      default:
        return theme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final total = rota['total'] as int;
    final metodo = rota['metodo'] as String;
    final cor = _corMetodo(metodo, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.border)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(6)),
            child: Text(metodo, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(rota['rota'] as String, style: TextStyle(fontSize: 13, color: theme.textDark, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total / maior,
                minHeight: 7,
                backgroundColor: theme.border,
                color: theme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text('${total}x', style: TextStyle(fontSize: 13, color: theme.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LinhaUsoEmpresa extends StatelessWidget {
  final Map<String, dynamic> uso;
  final int maior;

  const _LinhaUsoEmpresa({required this.uso, required this.maior});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final total = uso['totalChamadas'] as int;
    final nome = uso['nome'] as String;
    final id = uso['empresaId'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminAvatar(nome: nome, tamanho: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: theme.textDark)),
                    if (id != null)
                      Text('ID: #${id.substring(0, id.length >= 8 ? 8 : id.length)}',
                          style: TextStyle(fontSize: 11, color: theme.textMuted, fontFamily: 'monospace')),
                  ],
                ),
              ),
              Text('$total chamadas', style: TextStyle(fontSize: 13, color: theme.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: total / maior, minHeight: 6, backgroundColor: theme.border, color: theme.primary),
          ),
        ],
      ),
    );
  }
}
