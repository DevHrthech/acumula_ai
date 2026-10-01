import 'package:flutter/material.dart';
import '../services/empresa_api.dart';
import '../state/empresa_config.dart';
import '../state/empresa_session.dart';
import '../theme/app_colors.dart';
import '../widgets/color_picker_field.dart';
import '../widgets/web_sidebar.dart';

/// Configuração da loja: dados básicos, imagens de marca e a mecânica de
/// fidelidade (marcações ou pontos — ver docs/MECANICA_FIDELIDADE.md).
class WebConfiguracoesScreen extends StatefulWidget {
  final ValueChanged<AdminSection> onSelect;
  const WebConfiguracoesScreen({super.key, required this.onSelect});

  @override
  State<WebConfiguracoesScreen> createState() =>
      _WebConfiguracoesScreenState();
}

class _RegraRow {
  final TextEditingController descricao;
  final TextEditingController pontos;
  _RegraRow({required String descricao, required int pontos})
      : descricao = TextEditingController(text: descricao),
        pontos = TextEditingController(text: pontos.toString());

  void dispose() {
    descricao.dispose();
    pontos.dispose();
  }
}

class _WebConfiguracoesScreenState extends State<WebConfiguracoesScreen> {
  late final TextEditingController _nome;
  late final TextEditingController _meta;
  late final TextEditingController _recompensa;
  late String _categoria;
  late TipoFidelidade _tipo;
  late Color _corPrincipal;
  late Color _corDestaque;
  late final TextEditingController _nomePrograma;
  late final TextEditingController _mensagemBoasVindas;
  late final TextEditingController _mensagemResgate;
  late final TextEditingController _textoBotaoResgate;
  final List<_RegraRow> _regras = [];

  static const _categorias = [
    'Cafeteria',
    'Beleza',
    'Restaurante',
    'Mercado',
    'Outro',
  ];


  @override
  void initState() {
    super.initState();
    final config = EmpresaConfigScope.of(context);
    _nome = TextEditingController(text: config.nome);
    _categoria = config.categoria;
    _tipo = config.tipoFidelidade;
    _meta = TextEditingController(text: config.metaFidelidade.toString());
    _recompensa = TextEditingController(text: config.descricaoRecompensa);
    _corPrincipal = config.corPrincipal;
    _corDestaque = config.corDestaque;
    _nomePrograma = TextEditingController(text: config.nomePrograma);
    _mensagemBoasVindas = TextEditingController(text: config.mensagemBoasVindas);
    _mensagemResgate = TextEditingController(text: config.mensagemResgate);
    _textoBotaoResgate = TextEditingController(text: config.textoBotaoResgate);
    for (final r in config.regrasPontuacao) {
      _regras.add(_RegraRow(descricao: r.descricao, pontos: r.pontos));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _meta.dispose();
    _recompensa.dispose();
    _nomePrograma.dispose();
    _mensagemBoasVindas.dispose();
    _mensagemResgate.dispose();
    _textoBotaoResgate.dispose();
    for (final r in _regras) {
      r.dispose();
    }
    super.dispose();
  }

  bool _salvando = false;

  Future<void> _salvar() async {
    final config = EmpresaConfigScope.of(context);
    final session = EmpresaSessionScope.of(context);
    final nome = _nome.text.trim().isEmpty ? config.nome : _nome.text.trim();
    final metaFidelidade = int.tryParse(_meta.text) ?? config.metaFidelidade;
    final descricaoRecompensa = _recompensa.text.trim();
    final nomePrograma = _nomePrograma.text.trim().isEmpty
        ? config.nomePrograma
        : _nomePrograma.text.trim();
    final mensagemBoasVindas = _mensagemBoasVindas.text.trim();
    final mensagemResgate = _mensagemResgate.text.trim();
    final textoBotaoResgate = _textoBotaoResgate.text.trim().isEmpty
        ? config.textoBotaoResgate
        : _textoBotaoResgate.text.trim();

    setState(() => _salvando = true);
    try {
      // Mecânica de fidelidade (marcações/pontos) e regras de pontuação
      // ainda não têm suporte no servidor (fixa após o cadastro, ver
      // docs/MECANICA_FIDELIDADE.md) — não são enviadas no PATCH; os demais
      // campos abaixo são persistidos de verdade.
      final atualizado = await session.api.atualizarMe({
        'nome': nome,
        'categoria': _categoria,
        'metaFidelidade': metaFidelidade,
        'descricaoRecompensa': descricaoRecompensa,
        'corPrincipal': ColorPickerField.hexDe(_corPrincipal),
        'corDestaque': ColorPickerField.hexDe(_corDestaque),
        'nomePrograma': nomePrograma,
        'mensagemBoasVindas': mensagemBoasVindas,
        'mensagemResgate': mensagemResgate,
        'textoBotaoResgate': textoBotaoResgate,
      });

      config.carregarDe(atualizado);
      config.aplicarSelecaoLocal(
        tipoFidelidade: _tipo,
        regrasPontuacao: _regras
            .map((r) => RegraPontuacao(
                  descricao: r.descricao.text.trim(),
                  pontos: int.tryParse(r.pontos.text) ?? 0,
                ))
            .toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas.')),
      );
    } on EmpresaApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar. Tente novamente.'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _adicionarRegra() {
    setState(() {
      _regras.add(_RegraRow(descricao: '', pontos: 0));
    });
  }

  void _removerRegra(int index) {
    setState(() {
      _regras.removeAt(index).dispose();
    });
  }

  String get _metaLabel =>
      _tipo == TipoFidelidade.marcacoes ? 'Marcações' : 'Pontos';

  @override
  Widget build(BuildContext context) {
    return WebShell(
      current: AdminSection.configuracoes,
      onSelect: widget.onSelect,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WebPageHeader(
              title: 'Configurações',
              subtitle:
                  'Dados da loja, identidade visual e a mecânica de fidelidade do seu programa.',
            ),
            const SizedBox(height: 24),
            _card(
              title: 'Dados da loja',
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _field(
                        label: 'Nome da loja',
                        child: TextFormField(
                          controller: _nome,
                          decoration: _inputDecoration('Nome da sua loja'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _field(
                        label: 'Categoria',
                        child: DropdownButtonFormField<String>(
                          initialValue: _categoria,
                          isExpanded: true,
                          decoration: _inputDecoration(''),
                          items: _categorias
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textDark)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _categoria = v ?? _categoria),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _card(
              title: 'Identidade visual',
              subtitle: 'Imagens da sua marca, usadas no app do cliente.',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _uploadBox(
                        label: 'Ícone',
                        hint: 'PNG, fundo transparente, quadrado (mín. 512×512px)',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _uploadBox(
                        label: 'Logo para o QR Code',
                        hint: 'PNG, quadrado (mín. 512×512px)',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _uploadBox(
                        label: 'Logo para promoções',
                        hint: 'PNG ou JPG, paisagem (mín. 1200×630px)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _card(
              title: 'Cores da loja',
              subtitle:
                  'Essas cores aparecem no cartão fidelidade que o cliente vê no app.',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ColorPickerField(
                        label: 'Cor principal',
                        color: _corPrincipal,
                        onChanged: (c) => setState(() => _corPrincipal = c),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ColorPickerField(
                        label: 'Cor de destaque',
                        color: _corDestaque,
                        onChanged: (c) => setState(() => _corDestaque = c),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_corPrincipal, _corPrincipal.withValues(alpha: 0.8)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.card_giftcard, color: _corDestaque),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nome.text.isEmpty ? 'Nome da loja' : _nome.text,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            Text(
                              'Prévia do cartão fidelidade',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _card(
              title: 'Textos personalizados',
              subtitle:
                  'Textos que o cliente final vê no app (nome do programa, mensagens e botão de resgate).',
              children: [
                _field(
                  label: 'Nome do programa de fidelidade',
                  child: TextFormField(
                    controller: _nomePrograma,
                    decoration: _inputDecoration('Ex: Cartão Fidelidade'),
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Mensagem de boas-vindas',
                  child: TextFormField(
                    controller: _mensagemBoasVindas,
                    maxLines: 2,
                    decoration: _inputDecoration(
                        'Mostrada ao cliente quando ele vincula à sua loja'),
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Mensagem de resgate',
                  child: TextFormField(
                    controller: _mensagemResgate,
                    maxLines: 2,
                    decoration: _inputDecoration(
                        'Mostrada quando o cliente resgata a recompensa'),
                  ),
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'Texto do botão de resgate',
                  child: TextFormField(
                    controller: _textoBotaoResgate,
                    decoration: _inputDecoration('Ex: Resgatar recompensa'),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _nomePrograma,
                    _mensagemBoasVindas,
                    _textoBotaoResgate,
                  ]),
                  builder: (context, _) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nomePrograma.text.isEmpty
                              ? 'Nome do programa'
                              : _nomePrograma.text,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _mensagemBoasVindas.text.isEmpty
                              ? 'Mensagem de boas-vindas aparecerá aqui...'
                              : _mensagemBoasVindas.text,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _textoBotaoResgate.text.isEmpty
                                ? 'Resgatar recompensa'
                                : _textoBotaoResgate.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _card(
              title: 'Mecânica de fidelidade',
              subtitle:
                  'Escolha como o programa de fidelidade contínuo da sua loja funciona. Campanhas específicas sempre seguem esta mesma mecânica.',
              children: [
                RadioGroup<TipoFidelidade>(
                  groupValue: _tipo,
                  onChanged: (v) => setState(() => _tipo = v!),
                  child: Row(
                    children: [
                      Expanded(
                        child: _tipoOption(
                          tipo: TipoFidelidade.marcacoes,
                          titulo: 'Marcações',
                          descricao:
                              'Contador fixo por compra (ex: 10 compras = 1 recompensa). Zera ao resgatar.',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _tipoOption(
                          tipo: TipoFidelidade.pontos,
                          titulo: 'Pontos',
                          descricao:
                              'Saldo acumulado por regras de pontuação. Resgate desconta só o valor da meta.',
                          icon: Icons.toll_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _field(
                        label: 'Meta de $_metaLabel',
                        child: TextFormField(
                          controller: _meta,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('Ex: 10'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _field(
                        label: 'Descrição da recompensa',
                        child: TextFormField(
                          controller: _recompensa,
                          decoration:
                              _inputDecoration('Ex: 1 esmalte grátis à sua escolha'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'A mecânica não pode ser alterada depois que a loja já tiver clientes com progresso ativo.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            if (_tipo == TipoFidelidade.pontos) ...[
              const SizedBox(height: 20),
              _card(
                title: 'Regras de pontuação',
                subtitle:
                    'Quantos pontos cada marcação concede. O critério de quando cada regra se aplica ainda será definido — por ora, cadastre livremente.',
                children: [
                  ...List.generate(_regras.length, (i) {
                    final regra = _regras[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: regra.descricao,
                              decoration:
                                  _inputDecoration('Ex: Padrão, Café especial...'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: regra.pontos,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Pontos'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed:
                                _regras.length > 1 ? () => _removerRegra(i) : null,
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger, size: 20),
                          ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _adicionarRegra,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar regra'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _card(
              title: 'Cartão de exemplo',
              subtitle:
                  'É assim que o cartão fidelidade da sua loja vai aparecer para o cliente no app — tudo o que você configurou acima (cores, textos e mecânica) reunido num só lugar.',
              children: [
                Center(child: _buildCartaoExemplo()),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                child: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar alterações'),
              ),
            ),
            const SizedBox(height: 28),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildCartaoExemplo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _nomePrograma,
        _nome,
        _meta,
        _recompensa,
        _textoBotaoResgate,
      ]),
      builder: (context, _) {
        final total = int.tryParse(_meta.text) ?? 10;
        final atual = (total * 0.6).round().clamp(0, total > 0 ? total - 1 : 0);
        final progresso = total == 0 ? 0.0 : atual / total;
        final nomePrograma =
            _nomePrograma.text.isEmpty ? 'Cartão Fidelidade' : _nomePrograma.text;
        final nomeLoja = _nome.text.isEmpty ? 'Sua loja' : _nome.text;
        final recompensa = _recompensa.text.isEmpty
            ? 'Descrição da recompensa'
            : _recompensa.text;

        return Container(
          width: 360,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_corPrincipal, _corPrincipal.withValues(alpha: 0.82)],
            ),
            boxShadow: [
              BoxShadow(
                color: _corPrincipal.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.card_giftcard, color: _corDestaque, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomePrograma,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          nomeLoja,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progresso',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$atual de $total $_metaLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progresso,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: AlwaysStoppedAnimation<Color>(_corDestaque),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.redeem, size: 16, color: _corDestaque),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recompensa,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _textoBotaoResgate.text.isEmpty
                      ? 'Resgatar recompensa'
                      : _textoBotaoResgate.text,
                  style: TextStyle(
                    color: _corPrincipal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tipoOption({
    required TipoFidelidade tipo,
    required String titulo,
    required String descricao,
    required IconData icon,
  }) {
    final selected = _tipo == tipo;
    return InkWell(
      onTap: () => setState(() => _tipo = tipo),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Radio<TipoFidelidade>(
                  value: tipo,
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              descricao,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadBox({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.cloud_upload_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _card({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.primary, width: 1.4),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );
}
