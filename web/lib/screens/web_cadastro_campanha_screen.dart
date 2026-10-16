import 'package:flutter/material.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../services/empresa_api.dart';
import '../theme/app_colors.dart';
import '../widgets/web_sidebar.dart';

class WebCadastroCampanhaScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebCadastroCampanhaScreen({super.key, required this.onSelect});

  @override
  State<WebCadastroCampanhaScreen> createState() => _WebCadastroCampanhaScreenState();
}

class _WebCadastroCampanhaScreenState extends State<WebCadastroCampanhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _meta = TextEditingController();
  DateTime? _dataInicio; // opcional: sem data, vale a do cadastro
  DateTime? _dataValidade;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _meta.dispose();
    super.dispose();
  }

  Future<void> _selecionarValidade() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataValidade ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _dataValidade = picked);
    }
  }

  Future<void> _selecionarInicio() async {
    final hoje = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? hoje,
      firstDate: DateTime(hoje.year, hoje.month, hoje.day),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dataInicio = picked);
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String get _metaLabel {
    final tipo = EmpresaConfigScope.of(context).tipoFidelidade;
    return tipo == TipoFidelidade.marcacoes ? 'Marcações' : 'Pontos';
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataValidade == null) {
      setState(() => _erro = 'Selecione a data de validade.');
      return;
    }
    final meta = int.tryParse(_meta.text.trim());
    if (meta == null || meta < 1) {
      setState(() => _erro = 'Meta deve ser um número inteiro maior que zero.');
      return;
    }
    if (_dataInicio != null && _dataInicio!.isAfter(_dataValidade!)) {
      setState(() => _erro = 'O início não pode ser depois da validade.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final session = EmpresaSessionScope.of(context);
      await session.api.criarCampanha(
        nome: _nome.text.trim(),
        descricao: _descricao.text.trim(),
        meta: meta,
        dataValidade: _dataValidade!.toIso8601String(),
        dataInicio: _dataInicio?.toIso8601String(),
      );
      if (!mounted) return;
      widget.onSelect(AdminSection.campanhas);
    } on EmpresaApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível cadastrar a campanha.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.cadastro,
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
                    children: [
                      Expanded(flex: 3, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: preview),
                    ],
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
      onPressed: () => widget.onSelect(AdminSection.campanhas),
      icon: const Icon(Icons.arrow_back, size: 16),
      label: const Text('Voltar para Campanhas'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.add_box_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cadastrar Nova Campanha', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      Text('Crie uma campanha de fidelidade para engajar clientes', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionTitle('INFORMAÇÕES BÁSICAS'),
            const SizedBox(height: 14),
            _Field(
              label: 'Nome da Campanha *',
              child: TextFormField(controller: _nome, decoration: _inputDecoration('Ex: Café da Manhã Especial'), validator: _required),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Descrição *',
              child: TextFormField(
                controller: _descricao,
                maxLines: 4,
                decoration: _inputDecoration('Descreva a recompensa e as regras da campanha...'),
                validator: _required,
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle('CONFIGURAÇÃO'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Meta de $_metaLabel *',
                    child: TextFormField(
                      controller: _meta,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Ex: 10'),
                      validator: _required,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _Field(
                    label: 'Validade *',
                    child: InkWell(
                      onTap: _selecionarValidade,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: _inputDecoration('Selecione a data'),
                        child: Text(
                          _dataValidade == null
                              ? ''
                              : '${_dataValidade!.day.toString().padLeft(2, '0')}/${_dataValidade!.month.toString().padLeft(2, '0')}/${_dataValidade!.year}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                        decoration: _inputDecoration('Sem data: vale a data do cadastro'),
                        child: Text(
                          _dataInicio == null ? '' : _fmt(_dataInicio!),
                          style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
                  if (_dataInicio != null)
                    IconButton(
                      tooltip: 'Usar a data do cadastro',
                      onPressed: () => setState(() => _dataInicio = null),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _cadastrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _salvando
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Cadastrar Campanha', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Pré-visualização', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: const Center(child: Icon(Icons.campaign_outlined, color: Colors.white70, size: 32)),
          ),
          const SizedBox(height: 14),
          Text(
            _nome.text.isEmpty ? 'Nome da Campanha' : _nome.text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            _descricao.text.isEmpty ? 'Descrição da campanha aparecerá aqui...' : _descricao.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: _metaLabel, value: _meta.text.isEmpty ? '0' : _meta.text),
              _Stat(
                label: 'Validade',
                value: _dataValidade == null ? '-' : '${_dataValidade!.day.toString().padLeft(2, '0')}/${_dataValidade!.month.toString().padLeft(2, '0')}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _required(String? v) => v == null || v.trim().isEmpty ? 'Campo obrigatório' : null;

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 1.4)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.danger)),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
