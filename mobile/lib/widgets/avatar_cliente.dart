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

  Widget _inicial() {
    final texto = nome.trim();
    if (texto.isEmpty) return Icon(Icons.person, color: corTexto, size: tamanho * 0.55);
    return Text(
      texto[0].toUpperCase(),
      style: TextStyle(fontSize: tamanho * 0.44, fontWeight: FontWeight.bold, color: corTexto),
    );
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = fotoUrl != null && fotoUrl!.isNotEmpty;
    return Container(
      width: tamanho,
      height: tamanho,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fundo,
        border: borda == null ? null : Border.all(color: borda!, width: 3),
      ),
      child: temFoto
          ? Image.network(
              fotoUrl!,
              width: tamanho,
              height: tamanho,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _inicial(),
              loadingBuilder: (context, child, progresso) => progresso == null ? child : _inicial(),
            )
          : _inicial(),
    );
  }
}
