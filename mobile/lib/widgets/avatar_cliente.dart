import 'package:flutter/material.dart';

/// Foto de perfil do cliente em círculo. Sem foto (ou se ela não carregar)
/// mostra a inicial do nome — ou um ícone de pessoa, se não houver nome.
class AvatarCliente extends StatelessWidget {
  final String? fotoUrl;
  final String nome;
  final double tamanho;
  final Color fundo;
  final Color corTexto;
  final Color? borda;

  const AvatarCliente({
    super.key,
    required this.fotoUrl,
    required this.nome,
    required this.tamanho,
    required this.fundo,
    required this.corTexto,
    this.borda,
  });

  static const double _espessuraBorda = 3;

  Widget _inicial(double lado) {
    final texto = nome.trim();
    if (texto.isEmpty) return Icon(Icons.person, color: corTexto, size: lado * 0.55);
    return Text(
      texto[0].toUpperCase(),
      style: TextStyle(fontSize: lado * 0.44, fontWeight: FontWeight.bold, color: corTexto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    final espessura = borda == null ? 0.0 : _espessuraBorda;
    final interno = tamanho - 2 * espessura;
    // O anel (borda) é o fundo do círculo de fora e a foto é cortada num
    // ClipOval do tamanho EXATO do miolo. Antes a imagem tinha o tamanho do
    // círculo inteiro dentro de um Container com borda: sobrava um pedaço reto
    // em cada lado e a foto parecia um quadrado de cantos arredondados.
    return Container(
      width: tamanho,
      height: tamanho,
      padding: EdgeInsets.all(espessura),
      decoration: BoxDecoration(shape: BoxShape.circle, color: borda ?? fundo),
      child: ClipOval(
        child: Container(
          width: interno,
          height: interno,
          color: fundo,
          alignment: Alignment.center,
          child: temFoto
              ? Image.network(
                  fotoUrl!,
                  width: interno,
                  height: interno,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _inicial(interno),
                  loadingBuilder: (context, child, progresso) => progresso == null ? child : _inicial(interno),
                )
              : _inicial(interno),
        ),
      ),
    );
  }
}
