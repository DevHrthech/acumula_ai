import 'package:flutter/material.dart';

/// Dados reais de um vínculo (cliente↔loja) formatados pra exibição —
/// construído a partir da resposta de `GET /clientes/me/vinculos`
/// (ver mobile/lib/services/cliente_api.dart), nunca mais mockado.
class PromoDetailData {
  final String empresaId;
  final String storeName;
  final String? storeCategory;
  final Color corPrincipal;
  final String rewardDescription;
  final int currentStamps;
  final int totalStamps;
  final String unidade;

  const PromoDetailData({
    required this.empresaId,
    required this.storeName,
    required this.storeCategory,
    required this.corPrincipal,
    required this.rewardDescription,
    required this.currentStamps,
    required this.totalStamps,
    required this.unidade,
  });

  double get progress => totalStamps == 0 ? 0 : (currentStamps / totalStamps).clamp(0, 1);

  factory PromoDetailData.fromVinculo(Map<String, dynamic> vinculo) {
    final empresa = vinculo['empresa'] as Map<String, dynamic>;
    return PromoDetailData(
      empresaId: empresa['id'] as String,
      storeName: empresa['nome'] as String,
      storeCategory: empresa['categoria'] as String?,
      corPrincipal: corDeHex(empresa['cor_principal'] as String),
      rewardDescription: empresa['descricao_recompensa'] as String,
      currentStamps: vinculo['saldoAtual'] as int,
      totalStamps: empresa['meta_fidelidade'] as int,
      unidade: (empresa['tipo_fidelidade'] as String) == 'PONTOS' ? 'pontos' : 'selos',
    );
  }
}

Color corDeHex(String hex) {
  final valor = hex.replaceFirst('#', '');
  return Color(int.parse('FF$valor', radix: 16));
}
