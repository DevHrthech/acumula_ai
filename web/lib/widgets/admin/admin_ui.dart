import 'package:flutter/material.dart';
import '../../theme/theme_provider.dart';

/// Kit de componentes visuais do painel administrativo interno da 2RL
/// (telas em screens/admin). Puramente apresentação — nenhuma chamada de
/// rede ou regra de negócio vive aqui.

/// Duas iniciais a partir do nome da empresa, pro avatar circular.
String iniciaisNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) {
    return partes.first.substring(0, partes.first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

/// "1234" -> "1.234". Sem pacote `intl` — o projeto não usa.
String formatarMilhar(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// "1234.5" -> "1.234,50".
String formatarMoeda(num v) {
  final fixo = v.toStringAsFixed(2).replaceAll('.', ',');
  final partes = fixo.split(',');
  return '${formatarMilhar(int.parse(partes[0]))},${partes[1]}';
}

/// Validação de dígito verificador de CNPJ — só para exibir o selo "Válido"
/// no cadastro (o CNPJ já foi validado no servidor ao criar a empresa);
/// mesmo algoritmo de server/src/utils/cnpj.js, replicado aqui pro
/// front-end não depender de uma chamada à API só pra isso.
bool cnpjValido(String cnpj) {
  final digitos = cnpj.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(digitos)) return false;

  int calcularDigito(String base, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += int.parse(base[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final base = digitos.substring(0, 12);
  final dv1 = calcularDigito(base, pesos1);
  final dv2 = calcularDigito('$base$dv1', pesos2);
  return digitos == '$base$dv1$dv2';
}

/// Avatar circular com as iniciais da empresa/pessoa.
class AdminAvatar extends StatelessWidget {
  final String nome;
  final double tamanho;
  final Color? corTexto;
  final Color? corFundo;
  final Color? corBorda;

  const AdminAvatar({
    super.key,
    required this.nome,
    this.tamanho = 48,
    this.corTexto,
    this.corFundo,
    this.corBorda,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: corFundo ?? theme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: corBorda ?? theme.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        iniciaisNome(nome),
        style: TextStyle(
          color: corTexto ?? theme.primary,
          fontWeight: FontWeight.bold,
          fontSize: tamanho * 0.34,
        ),
      ),
    );
  }
}

/// Selo colorido de status (ex: ATIVA, INADIMPLENTE...).
class AdminBadge extends StatelessWidget {
  final String texto;
  final Color cor;
  final Color fundo;

  const AdminBadge({super.key, required this.texto, required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(8)),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
      ),
    );
  }
}

/// Card de métrica no topo das telas (ex: "TOTAL DE EMPRESAS").
class AdminStatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color corIcone;
  final String? legenda;
  final Color? corLegenda;
  final double largura;

  const AdminStatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
    this.legenda,
    this.corLegenda,
    this.largura = 230,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      width: largura,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.textMuted, letterSpacing: 0.4),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: corIcone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icone, size: 16, color: corIcone),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(valor, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.textDark)),
          const SizedBox(height: 4),
          // Sempre reserva a linha da legenda, mesmo vazia — assim todos os
          // cards de uma mesma fileira (Wrap não equaliza altura) ficam com
          // a mesma altura, tenham ou não legenda.
          Text(legenda ?? '', style: TextStyle(fontSize: 12, color: corLegenda ?? theme.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Cabeçalho padrão das telas internas (título + subtítulo + ações à direita).
class AdminPageHeader extends StatelessWidget {
  final String titulo;
  final String? contagem;
  final String subtitulo;
  final List<Widget> acoes;

  const AdminPageHeader({
    super.key,
    required this.titulo,
    this.contagem,
    required this.subtitulo,
    this.acoes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(titulo, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textDark)),
                  if (contagem != null) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(contagem!, style: TextStyle(fontSize: 13, color: theme.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(subtitulo, style: TextStyle(fontSize: 13, color: theme.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: acoes),
      ],
    );
  }
}

/// Botão de ícone circular/quadrado com borda (ex: atualizar).
class AdminIconButton extends StatelessWidget {
  final IconData icone;
  final VoidCallback onPressed;
  final String? tooltip;

  const AdminIconButton({super.key, required this.icone, required this.onPressed, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final botao = Container(
      decoration: BoxDecoration(border: Border.all(color: theme.border), borderRadius: BorderRadius.circular(10)),
      child: IconButton(icon: Icon(icone, size: 18, color: theme.textDark), onPressed: onPressed),
    );
    return tooltip == null ? botao : Tooltip(message: tooltip!, child: botao);
  }
}

/// Botão outline (ex: "Exportar CSV").
class AdminOutlineButton extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback? onPressed;

  const AdminOutlineButton({super.key, required this.icone, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textDark,
        side: BorderSide(color: theme.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Botão principal preenchido (cor da marca).
class AdminFilledButton extends StatelessWidget {
  final IconData? icone;
  final String label;
  final VoidCallback? onPressed;

  const AdminFilledButton({super.key, this.icone, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icone == null ? const SizedBox.shrink() : Icon(icone, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

/// Card de seção com ícone + título + subtítulo + ação opcional à direita.
class AdminSectionCard extends StatelessWidget {
  final IconData icone;
  final Color corIcone;
  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  final Widget child;

  const AdminSectionCard({
    super.key,
    required this.icone,
    required this.corIcone,
    required this.titulo,
    this.subtitulo,
    this.acao,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: corIcone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icone, size: 18, color: corIcone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textDark)),
                      if (subtitulo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitulo!, style: TextStyle(fontSize: 12, color: theme.textMuted)),
                        ),
                    ],
                  ),
                ),
                ?acao,
              ],
            ),
          ),
          Divider(height: 1, color: theme.border),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

/// Link de texto com ícone (ex: "Editar dados").
class AdminTextAction extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback? onPressed;
  final Color? cor;

  const AdminTextAction({super.key, required this.icone, required this.label, this.onPressed, this.cor});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icone, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(foregroundColor: cor ?? theme.primary),
    );
  }
}

/// Estado vazio (ex: "Nenhuma licença atribuída").
class AdminEmptyState extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const AdminEmptyState({super.key, required this.icone, required this.titulo, required this.descricao});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(border: Border.all(color: theme.border), borderRadius: BorderRadius.circular(12), color: theme.bgPage),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.surface, border: Border.all(color: theme.border)),
            child: Icon(icone, color: theme.textMuted, size: 22),
          ),
          const SizedBox(height: 14),
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textDark, fontSize: 14)),
          const SizedBox(height: 6),
          Text(descricao, textAlign: TextAlign.center, style: TextStyle(color: theme.textMuted, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Moldura de diálogo com ícone + título + subtítulo + fechar, usada em
/// todos os formulários do painel. O conteúdo e os botões de rodapé ficam a
/// cargo de quem chama — aqui só é visual. `Navigator.pop(false)` no "x" tem
/// o mesmo efeito de "Cancelar".
class AdminDialogShell extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;
  final Widget? selo;
  final double largura;
  final Widget conteudo;
  final List<Widget> acoes;
  final Widget? acaoExtra;

  const AdminDialogShell({
    super.key,
    required this.icone,
    required this.titulo,
    this.subtitulo,
    this.selo,
    this.largura = 480,
    required this.conteudo,
    required this.acoes,
    this.acaoExtra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largura),
        child: Container(
          decoration: BoxDecoration(color: theme.cardBg, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icone, color: theme.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark)),
                              ),
                              if (selo != null) ...[const SizedBox(width: 8), selo!],
                            ],
                          ),
                          if (subtitulo != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(subtitulo!, style: TextStyle(fontSize: 12.5, color: theme.textMuted)),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: theme.textMuted,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: conteudo,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Row(
                  children: [
                    if (acaoExtra != null) ...[acaoExtra!, const Spacer()] else const Spacer(),
                    ...acoes,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de texto padronizado (label acima, caixa arredondada).
class AdminField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? helper;
  final bool obscure;
  final TextInputType? teclado;
  final int maxLinhas;
  final VoidCallback? onSubmitted;

  const AdminField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.helper,
    this.obscure = false,
    this.teclado,
    this.maxLinhas = 1,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: teclado,
            maxLines: maxLinhas,
            onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: theme.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.primary, width: 1.5)),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(helper!, style: TextStyle(fontSize: 11.5, color: theme.textMuted)),
            ),
        ],
      ),
    );
  }
}

/// Dropdown padronizado (label acima, mesma caixa do AdminField).
class AdminDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? helper;

  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.inputBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: theme.primary, width: 1.5)),
            ),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(helper!, style: TextStyle(fontSize: 11.5, color: theme.textMuted)),
            ),
        ],
      ),
    );
  }
}

/// Botões padrão de rodapé de diálogo (Cancelar / Confirmar).
class AdminDialogActions {
  static Widget cancelar(BuildContext context, {String label = 'Cancelar'}) {
    final theme = ThemeScope.of(context);
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(false),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.textDark,
        side: BorderSide(color: theme.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  static Widget confirmar(BuildContext context, String label, {IconData icone = Icons.check}) {
    final theme = ThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).pop(true),
        icon: Icon(icone, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

/// Moldura visual compartilhada pelas telas de autenticação do painel admin
/// (login, recuperar senha): fundo em gradiente, card central com sombra, e
/// o rodapé institucional (links + copyright). `conteudoCard` é o miolo do
/// card (ícone, pílula, título, campos...); `rodapeExterno` é o link logo
/// abaixo do card (varia por tela — "Problemas com o acesso?", "Voltar pro
/// login"...).
class AdminAuthScaffold extends StatelessWidget {
  final Widget conteudoCard;
  final Widget? rodapeExterno;

  const AdminAuthScaffold({super.key, required this.conteudoCard, this.rodapeExterno});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: theme.isDarkMode
                    ? [const Color(0xFF17122B), const Color(0xFF0D0D14)]
                    : [const Color(0xFFF2ECFA), const Color(0xFFFAFAFC)],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(40, 32, 40, 24),
                          decoration: BoxDecoration(
                            color: theme.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 16))],
                          ),
                          child: conteudoCard,
                        ),
                      ),
                      if (rodapeExterno != null) ...[
                        const SizedBox(height: 18),
                        rodapeExterno!,
                      ],
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 18,
                        runSpacing: 6,
                        children: [
                          Text('Termos de Uso', style: TextStyle(color: theme.textHint, fontSize: 12)),
                          Text('Política de Segurança', style: TextStyle(color: theme.textHint, fontSize: 12)),
                          Text('Contrato de Licenciamento', style: TextStyle(color: theme.textHint, fontSize: 12)),
                          Text('Status dos Serviços', style: TextStyle(color: theme.textHint, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© ${DateTime.now().year} 2RL Tecnologia & Sistemas. Todos os direitos reservados.',
                        style: TextStyle(color: theme.textHint, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pílula pequena usada no topo dos cards de autenticação (ex: "Acesso
/// Restrito / Admin").
class AdminAuthPill extends StatelessWidget {
  final String texto;
  const AdminAuthPill({super.key, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(texto, style: TextStyle(color: theme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Ícone quadrado com gradiente da marca + selo circular no canto, usado no
/// topo dos cards de autenticação.
class AdminAuthIcon extends StatelessWidget {
  final IconData icone;
  final IconData iconeSelo;
  final Color? corSelo;

  const AdminAuthIcon({super.key, required this.icone, this.iconeSelo = Icons.check_circle, this.corSelo});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primary, theme.primaryDark]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icone, color: Colors.white, size: 40),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
              ),
              child: Icon(iconeSelo, color: corSelo ?? theme.success, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de texto dos cards de autenticação (ícone dentro do campo, cantos
/// mais arredondados que o `AdminField` padrão — visual mais "premium").
class AdminAuthField extends StatelessWidget {
  final String? label;
  final TextEditingController controller;
  final String? placeholder;
  final bool obscure;
  final TextInputType? teclado;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const AdminAuthField({
    super.key,
    this.label,
    required this.controller,
    this.placeholder,
    this.obscure = false,
    this.teclado,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: teclado,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: placeholder,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.inputBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Botão principal dos cards de autenticação (preenchido, largura total).
class AdminAuthButton extends StatelessWidget {
  final String label;
  final IconData icone;
  final bool carregando;
  final VoidCallback? onPressed;

  const AdminAuthButton({super.key, required this.label, this.icone = Icons.arrow_forward, this.carregando = false, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: carregando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: carregando
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Icon(icone, size: 18),
                ],
              ),
      ),
    );
  }
}

/// Linha "conexão criptografada" no rodapé dos cards de autenticação. Não
/// cita versão de TLS/bits — o app não tem como verificar isso, só que a
/// chamada é HTTPS.
class AdminAuthSeguranca extends StatelessWidget {
  const AdminAuthSeguranca({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_outlined, size: 15, color: theme.success),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Conexão criptografada de ponta a ponta (HTTPS)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: theme.textMuted),
          ),
        ),
      ],
    );
  }
}
