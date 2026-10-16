import 'package:flutter/material.dart';

/// Logo da loja (o "Ícone" enviado em Configurações do painel) no lugar do
/// ícone genérico de loja. Sem imagem — ou se ela não carregar — mostra o
/// [icone] de sempre, então nunca fica um buraco na tela.
class LojaLogo extends StatelessWidget {
  final String? url;
  final double tamanho;
  final IconData icone;
  final Color corIcone;

  /// Fundo atrás da logo. Logos são PNG com fundo transparente: sobre o
  /// degradê colorido da loja precisam de um fundo claro para aparecer.
  final Color fundo;
  final double raio;

  const LojaLogo({
    super.key,
    required this.url,
    required this.tamanho,
    this.icone = Icons.storefront,
    required this.corIcone,
    this.fundo = Colors.transparent,
    this.raio = 12,
  });

  @override
  Widget build(BuildContext context) {
    final iconePadrao = Icon(icone, color: corIcone, size: tamanho * 0.5);
    final temLogo = url != null && url!.isNotEmpty;
    return Container(
      width: tamanho,
      height: tamanho,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(raio)),
      child: temLogo
          ? Padding(
              padding: EdgeInsets.all(tamanho * 0.1),
              child: Image.network(
                url!,
                fit: BoxFit.contain,
                width: tamanho,
                height: tamanho,
                errorBuilder: (_, _, _) => iconePadrao,
                loadingBuilder: (context, child, progresso) => progresso == null ? child : iconePadrao,
              ),
            )
          : iconePadrao,
    );
  }
}
