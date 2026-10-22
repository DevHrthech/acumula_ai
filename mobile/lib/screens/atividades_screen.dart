import 'package:flutter/material.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';

/// Histórico recente (marcações, resgates e solicitações), aberto pelo sino
/// da tela Início.
class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  List<dynamic>? _itens;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final itens = await ClienteSessionScope.of(context).api.atividades();
      if (mounted) setState(() => _itens = itens);
    } on ClienteApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível carregar suas atividades.');
    }
  }

  String _dataFormatada(String iso) {
    final d = DateTime.parse(iso).toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} às ${dois(d.hour)}:${dois(d.minute)}';
  }

  ({IconData icone, Color cor, String titulo}) _descrever(Map<String, dynamic> item) {
    final loja = item['loja'] as String? ?? 'loja';
    switch (item['tipo']) {
      case 'MARCACAO':
        final pontos = item['pontos'] as int?;
        return (
          icone: Icons.check_circle_outline,
          cor: Colors.green,
          titulo: pontos != null ? '$pontos pontos creditados em $loja' : 'Marcação registrada em $loja',
        );
      case 'RESGATE':
        return (icone: Icons.card_giftcard, cor: const Color(0xFFE59500), titulo: 'Recompensa liberada em $loja');
      default:
        final status = item['status'] as String?;
        if (status == 'APROVADA') {
          return (icone: Icons.verified_outlined, cor: Colors.green, titulo: 'Solicitação aprovada por $loja');
        }
        if (status == 'REJEITADA') {
          return (icone: Icons.cancel_outlined, cor: Colors.red, titulo: 'Solicitação recusada por $loja');
        }
        return (icone: Icons.hourglass_empty, cor: Colors.blueGrey, titulo: 'Solicitação enviada a $loja, aguardando aprovação');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: theme.bgPage,
          appBar: AppBar(
            backgroundColor: theme.bgPage,
            elevation: 0,
            iconTheme: IconThemeData(color: theme.textDark),
            title: Text('Atividades', style: TextStyle(fontWeight: FontWeight.bold, color: theme.textDark)),
          ),
          body: _erro != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erro!, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted))))
              : _itens == null
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: _itens!.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(32),
                              children: [
                                const SizedBox(height: 60),
                                Icon(Icons.notifications_none, size: 44, color: theme.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma atividade ainda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Suas marcações, solicitações e resgates aparecem aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: theme.textMuted),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                              itemCount: _itens!.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final item = _itens![i] as Map<String, dynamic>;
                                final d = _descrever(item);
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(color: d.cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                        child: Icon(d.icone, color: d.cor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(d.titulo, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: theme.textDark)),
                                            const SizedBox(height: 3),
                                            Text(_dataFormatada(item['data'] as String), style: TextStyle(fontSize: 12, color: theme.textMuted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
        );
      },
    );
  }
}
