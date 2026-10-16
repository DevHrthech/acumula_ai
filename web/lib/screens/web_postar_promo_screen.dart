import 'package:flutter/material.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

/// Publica uma Promoção: um aviso/post que aparece na aba Promoções do app
/// dos clientes vinculados. Não tem meta e não gera cartão fidelidade (isso é
/// a Campanha, na tela "Cadastrar Campanha").
class WebPostarPromoScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebPostarPromoScreen({super.key, required this.onSelect});

  @override
  State<WebPostarPromoScreen> createState() => _WebPostarPromoScreenState();
}

class _WebPostarPromoScreenState extends State<WebPostarPromoScreen> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  DateTime? _inicio; // opcional: sem data, vale a do cadastro
  DateTime? _validade;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _selecionarValidade() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validade ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _validade = picked);
  }

  Future<void> _selecionarInicio() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _inicio ?? hoje,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _inicio = picked);
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _publicar() async {
    if (_titulo.text.trim().isEmpty || _descricao.text.trim().isEmpty) {
      setState(() => _erro = 'Preencha título e descrição.');
      return;
    }
    if (_inicio != null && _validade != null && _inicio!.isAfter(_validade!)) {
      setState(() => _erro = 'O início não pode ser depois do fim da validade.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      await session.api.criarPromocao(
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        dataValidade: _validade?.toIso8601String(),
        dataInicio: _inicio?.toIso8601String(),
      );
      if (!mounted) return;
      widget.onSelect(AdminSection.promocoes);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível publicar a promoção.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.postar,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackLink(),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth > 900;
                final form = _buildForm();
                final preview = _buildPreview();
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Expanded(flex: 3, child: form), const SizedBox(width: 20), Expanded(flex: 2, child: preview)],
                  );
                }
                return Column(children: [form, const SizedBox(height: 20), preview]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return TextButton.icon(
      onPressed: () => widget.onSelect(AdminSection.promocoes),
      icon: const Icon(Icons.arrow_back, size: 16),
      label: const Text('Voltar para Promoções'),
      style: TextButton.styleFrom(foregroundColor: AppColors.primary, padding: EdgeInsets.zero, textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.campaign_outlined, color: AppColors.textDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Postar Nova Promoção', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text('Aviso que aparece na aba Promoções do app (não gera cartão fidelidade)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle('DETALHES DA PROMOÇÃO'),
          const SizedBox(height: 14),
          _Field(label: 'Título *', child: TextField(controller: _titulo, decoration: _input('Ex: Combo Família 2x1'), onChanged: (_) => setState(() {})),),
          const SizedBox(height: 16),
          _Field(
            label: 'Descrição *',
            child: TextField(controller: _descricao, maxLines: 4, decoration: _input('Descreva a oferta e as regras...'), onChanged: (_) => setState(() {})),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Início (opcional)',
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selecionarInicio,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: _input('Sem data: vale a data do cadastro'),
                      child: Text(
                        _inicio == null ? '' : _fmt(_inicio!),
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                  ),
                ),
                if (_inicio != null)
                  IconButton(
                    tooltip: 'Usar a data do cadastro',
                    onPressed: () => setState(() => _inicio = null),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Fim da validade (opcional)',
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selecionarValidade,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: _input('Sem data limite'),
                      child: Text(
                        _validade == null ? '' : '${_validade!.day.toString().padLeft(2, '0')}/${_validade!.month.toString().padLeft(2, '0')}/${_validade!.year}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      ),
                    ),
                  ),
                ),
                if (_validade != null)
                  IconButton(
                    tooltip: 'Remover validade',
                    onPressed: () => setState(() => _validade = null),
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 16),
            Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onSelect(AdminSection.promocoes),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _salvando ? null : _publicar,
                  icon: _salvando ? const SizedBox.shrink() : const Icon(Icons.send, size: 18),
                  label: _salvando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.textDark))
                      : const Text('Publicar Promoção', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_iphone, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Preview no app', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark])),
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.campaign_outlined, color: Colors.white70, size: 44)),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(99)),
                            child: const Text('PROMOÇÃO', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textDark, letterSpacing: 0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titulo.text.isEmpty ? 'Título da promoção' : _titulo.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _descricao.text.isEmpty ? 'Descrição da oferta aparecerá aqui...' : _descricao.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _validade == null
                                ? (_inicio == null ? 'Sem data limite' : 'A partir de ${_fmt(_inicio!)}')
                                : (_inicio == null ? 'Válido até ${_fmt(_validade!)}' : 'De ${_fmt(_inicio!)} até ${_fmt(_validade!)}'),
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _input(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.4)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
  );
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 0.9));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
