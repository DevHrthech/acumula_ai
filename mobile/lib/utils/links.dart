import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const urlPoliticaPrivacidade = 'https://acumulaai.com.br/privacidade.html';

Future<void> abrirPoliticaPrivacidade(BuildContext context) async {
  final aberto = await launchUrl(Uri.parse(urlPoliticaPrivacidade), mode: LaunchMode.externalApplication);
  if (!aberto && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir a política de privacidade.')),
    );
  }
}
