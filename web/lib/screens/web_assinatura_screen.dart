import 'package:flutter/material.dart';
import '../services/empresa_api.dart';
import '../state/empresa_session.dart';
import '../theme/app_colors.dart';
import '../utils/abrir_link.dart';
import '../widgets/web_sidebar.dart';

/// Assinatura da loja: trial de 15 dias, status da licença, forma de
/// pagamento e as faturas mensais (cobradas via gateway Asaas), com o link
/// para pagar cada uma.
class WebAssinaturaScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebAssinaturaScreen({super.key, required this.onSelect});

  @override
  State<WebAssinaturaScreen> createState() => _WebAssinaturaScreenState();
}

class _WebAssinaturaScreenState extends State<WebAssinaturaScreen> {
  bool _carregando = true;
  String? _erro;
  Map<String, dynamic>? _licenca;
  List<Map<String, dynamic>> _cobrancas = [];
  bool _notaAtiva = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await EmpresaSessionScope.of(context).api.minhaAssinatura();
      if (!mounted) return;
      setState(() {
        _licenca = dados['licenca'] as Map<String, dynamic>?;
        _cobrancas = (dados['cobrancas'] as List<dynamic>).cast<Map<String, dynamic>>();
        _notaAtiva = dados['nota_fiscal_ativa'] == true;
      });
    } on EmpresaApiException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível carregar a assinatura.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  /// Escolhe/troca Pix x cartão recorrente. Com assinatura ativa no Asaas ela é
  /// recriada na nova forma (a 1ª fatura continua vencendo ao fim do período pago).
  Future<void> _alterarForma(String formaAtual) async {
    String forma = formaAtual;
    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Forma de pagamento'),
          content: RadioGroup<String>(
            groupValue: forma,
            onChanged: (v) => setDialogState(() => forma = v ?? forma),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(value: 'PIX', title: Text('Pix')),
                RadioListTile<String>(value: 'CARTAO_RECORRENTE', title: Text('Cartão de crédito recorrente')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Voltar')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirmado != true || forma == formaAtual || !mounted) return;
    try {
      final r = await EmpresaSessionScope.of(context).api.alterarFormaPagamento(forma);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((r['aviso'] as String?) ?? 'Forma de pagamento atualizada.')),
      );
      _carregar();
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.assinatura,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebPageHeader(
              title: 'Assinatura',
              subtitle: 'Seu plano, o período de teste e as faturas da mensalidade.',
            ),
            const SizedBox(height: 22),
            if (_carregando)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (_erro != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Text(_erro!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _carregar, child: const Text('Tentar de novo')),
                  ]),
                ),
              )
            else if (_licenca == null)
              _aviso(Icons.info_outline, 'Sua conta ainda não tem um plano vinculado. Fale com a 2RL para contratar.')
            else ...[
              _buildResumo(_licenca!),
              const SizedBox(height: 22),
              _buildFaturas(),
            ],
            const SizedBox(height: 28),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  // ---- resumo ------------------------------------------------------------

  Widget _buildResumo(Map<String, dynamic> licenca) {
    final plano = licenca['plano'] as Map<String, dynamic>;
    final emTrial = licenca['em_trial'] == true;
    final status = licenca['status_efetivo'] as String;
    final vencimento = _data(licenca['data_vencimento'] as String);
    final dias = _diasAte(vencimento);
    final proxima = _proximaFatura();

    final chip = _statusLicenca(status, emTrial);
    final String periodo;
    if (emTrial) {
      periodo = dias >= 0
          ? 'Teste grátis até ${_fmt(vencimento)} — ${dias == 0 ? 'último dia' : 'restam $dias ${dias == 1 ? 'dia' : 'dias'}'}.'
          : 'O teste grátis terminou em ${_fmt(vencimento)}.';
    } else {
      periodo = 'Licença paga até ${_fmt(vencimento)}.';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${plano['nome']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              _Chip(texto: chip.$1, cor: chip.$2, fundo: chip.$3),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                '${_valorBR(plano['valor_mensal'])} por mês · ${_formaPagamento(licenca['forma_pagamento'] as String?)}',
                style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              if (status != 'CANCELADA')
                TextButton.icon(
                  onPressed: () => _alterarForma((licenca['forma_pagamento'] as String?) ?? 'PIX'),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Alterar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(emTrial ? Icons.card_giftcard_outlined : Icons.event_available_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(periodo, style: const TextStyle(fontSize: 14, color: AppColors.textDark))),
            ],
          ),
          if (status == 'INADIMPLENTE') ...[
            const SizedBox(height: 10),
            _faixa(
              Icons.warning_amber_rounded,
              'Existe uma fatura em atraso. Pague até o fim do prazo de tolerância para não ter o acesso bloqueado.',
              AppColors.dangerBg,
              AppColors.danger,
            ),
          ],
          if (licenca['assinatura_ativa'] != true) ...[
            const SizedBox(height: 10),
            _faixa(
              Icons.hourglass_empty,
              'A cobrança automática pelo Asaas ainda não foi ativada para a sua licença. Você já pode escolher a forma de pagamento acima; '
              'a 2RL ativa a cobrança e as faturas passam a aparecer aqui.',
              AppColors.warningBg,
              AppColors.warningText,
            ),
          ],
          if (proxima != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('PRÓXIMA FATURA', style: _headerStyle),
                      const SizedBox(height: 4),
                      Text(
                        '${_valorBR(proxima['valor'])} · vence em ${_fmt(_data(proxima['data_vencimento'] as String))}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  if (_temLink(proxima))
                    ElevatedButton.icon(
                      onPressed: () => abrirLink(proxima['invoice_url'] as String),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(_pagaComCartao(proxima) ? 'Pagar com cartão' : 'Pagar agora'),
                      style: _botaoPrimario(),
                    ),
                ],
              ),
            ),
            if (_pagaComCartao(proxima))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Você informa o cartão na página segura do Asaas. A 2RL não armazena dados do seu cartão.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 15, color: AppColors.textHint),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Os pagamentos são processados via gateway de pagamento Asaas.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- faturas -----------------------------------------------------------

  Widget _buildFaturas() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Text('Faturas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.bgPage,
            child: const Row(
              children: [
                SizedBox(width: 120, child: Text('VENCIMENTO', style: _headerStyle)),
                SizedBox(width: 110, child: Text('VALOR', style: _headerStyle)),
                SizedBox(width: 190, child: Text('SITUAÇÃO', style: _headerStyle)),
                SizedBox(width: 120, child: Text('PAGA EM', style: _headerStyle)),
                SizedBox(width: 170, child: Text('NOTA FISCAL', style: _headerStyle)),
                Expanded(child: Align(alignment: Alignment.centerRight, child: Text('FATURA', style: _headerStyle))),
              ],
            ),
          ),
          if (_cobrancas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhuma fatura gerada ainda. A primeira vence logo após o fim do período de teste.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          for (final c in _cobrancas) _linhaFatura(c),
        ],
      ),
    );
  }

  Widget _linhaFatura(Map<String, dynamic> c) {
    final chip = _statusCobranca(c['status'] as String);
    final paga = c['data_pagamento'] as String?;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(_fmt(_data(c['data_vencimento'] as String)), style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
          SizedBox(width: 110, child: Text(_valorBR(c['valor']), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark))),
          SizedBox(width: 190, child: Align(alignment: Alignment.centerLeft, child: _Chip(texto: chip.$1, cor: chip.$2, fundo: chip.$3))),
          SizedBox(width: 120, child: Text(paga == null ? '—' : _fmt(_data(paga)), style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          SizedBox(width: 170, child: _celulaNota(c)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _temLink(c)
                  ? TextButton.icon(
                      onPressed: () => abrirLink(c['invoice_url'] as String),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(_estaPaga(c['status'] as String) ? 'Ver fatura' : 'Abrir fatura'),
                    )
                  : const Text('—', style: TextStyle(color: AppColors.textHint)),
            ),
          ),
        ],
      ),
    );
  }

  /// Nota fiscal de serviço da fatura: PDF (DANFSe) e XML, quando já emitida.
  /// Fatura paga sem nota ainda mostra "Emitindo…" (a prefeitura pode demorar).
  Widget _celulaNota(Map<String, dynamic> c) {
    final nota = c['nota_fiscal'] as Map<String, dynamic>?;
    if (nota == null) {
      return Text(
        _notaAtiva && _estaPaga(c['status'] as String) ? 'Emitindo…' : '—',
        style: const TextStyle(fontSize: 13, color: AppColors.textHint),
      );
    }
    final numero = nota['numero'] as String?;
    final pdf = nota['pdf_url'] as String?;
    final xml = nota['xml_url'] as String?;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (pdf != null && pdf.isNotEmpty)
          Tooltip(
            message: numero == null ? 'Baixar a nota fiscal (PDF)' : 'Baixar a nota fiscal nº $numero (PDF)',
            child: TextButton.icon(
              onPressed: () => abrirLink(pdf),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('PDF'),
              style: _botaoNota(),
            ),
          ),
        if (xml != null && xml.isNotEmpty)
          Tooltip(
            message: 'Baixar o XML da nota fiscal',
            child: TextButton.icon(
              onPressed: () => abrirLink(xml),
              icon: const Icon(Icons.code, size: 16),
              label: const Text('XML'),
              style: _botaoNota(),
            ),
          ),
      ],
    );
  }

  ButtonStyle _botaoNota() => TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 30),
      );

  // ---- auxiliares --------------------------------------------------------

  /// Fatura em aberto mais próxima do vencimento (a que a empresa precisa pagar).
  Map<String, dynamic>? _proximaFatura() {
    final abertas = _cobrancas.where((c) => c['status'] == 'PENDING' || c['status'] == 'OVERDUE').toList()
      ..sort((a, b) => (a['data_vencimento'] as String).compareTo(b['data_vencimento'] as String));
    return abertas.isEmpty ? null : abertas.first;
  }

  bool _temLink(Map<String, dynamic> c) => (c['invoice_url'] as String?)?.isNotEmpty ?? false;
  bool _pagaComCartao(Map<String, dynamic> c) => c['forma_pagamento'] == 'CREDIT_CARD';
  bool _estaPaga(String s) => const ['RECEIVED', 'CONFIRMED', 'RECEIVED_IN_CASH'].contains(s);

  /// As datas chegam como ISO de uma coluna DATE (meia-noite UTC): usa só AAAA-MM-DD,
  /// sem converter de fuso (senão o dia recua no horário de Brasília).
  DateTime _data(String iso) {
    final p = iso.substring(0, 10).split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  int _diasAte(DateTime d) {
    final agora = DateTime.now();
    return d.difference(DateTime(agora.year, agora.month, agora.day)).inDays;
  }

  /// `valor` chega como texto decimal ("99.9") ou número.
  String _valorBR(dynamic valor) {
    final v = double.tryParse('$valor') ?? 0;
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formaPagamento(String? forma) {
    switch (forma) {
      case 'PIX':
        return 'Pix';
      case 'CARTAO_RECORRENTE':
        return 'Cartão de crédito recorrente';
      default:
        return 'Forma de pagamento não definida';
    }
  }

  (String, Color, Color) _statusLicenca(String status, bool emTrial) {
    switch (status) {
      case 'ATIVA':
        return emTrial
            ? ('Em teste grátis', AppColors.warningText, AppColors.warningBg)
            : ('Ativa', AppColors.successText, AppColors.successBg);
      case 'INADIMPLENTE':
        return ('Pagamento em atraso', AppColors.danger, AppColors.dangerBg);
      case 'BLOQUEADA':
        return ('Bloqueada', AppColors.danger, AppColors.dangerBg);
      default:
        return ('Cancelada', AppColors.textMuted, AppColors.bgPage);
    }
  }

  (String, Color, Color) _statusCobranca(String status) {
    switch (status) {
      case 'PENDING':
        return ('Aguardando pagamento', AppColors.warningText, AppColors.warningBg);
      case 'OVERDUE':
        return ('Vencida', AppColors.danger, AppColors.dangerBg);
      case 'RECEIVED':
      case 'CONFIRMED':
      case 'RECEIVED_IN_CASH':
        return ('Paga', AppColors.successText, AppColors.successBg);
      case 'REFUNDED':
        return ('Estornada', AppColors.textMuted, AppColors.bgPage);
      default:
        return (status, AppColors.textMuted, AppColors.bgPage);
    }
  }

  Widget _faixa(IconData icone, String texto, Color fundo, Color cor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: cor),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: TextStyle(fontSize: 13, color: cor))),
        ],
      ),
    );
  }

  Widget _aviso(IconData icone, String texto) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icone, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: const TextStyle(color: AppColors.textMuted))),
        ],
      ),
    );
  }

  ButtonStyle _botaoPrimario() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}

const _headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.7);

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;
  const _Chip({required this.texto, required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(20)),
      child: Text(texto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
    );
  }
}
