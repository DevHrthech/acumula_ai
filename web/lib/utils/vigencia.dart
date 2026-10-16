import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Situação de uma campanha/promoção como a API devolve em `status_efetivo`:
/// ATIVA, AGENDADA (início no futuro), VENCIDA (passou do fim) ou EXPIRADA
/// (encerrada à mão). Antes só existia o status gravado, então uma campanha
/// vencida continuava aparecendo como "Ativa".
String statusEfetivo(Map<String, dynamic> item) =>
    (item['status_efetivo'] ?? item['status']) as String;

/// Já terminou (por data ou por ter sido encerrada à mão).
bool estaEncerrada(String efetivo) => efetivo == 'EXPIRADA' || efetivo == 'VENCIDA';

class ApresentacaoStatus {
  final String texto;
  final Color cor;
  final Color fundo;
  const ApresentacaoStatus(this.texto, this.cor, this.fundo);
}

ApresentacaoStatus apresentarStatus(String efetivo) {
  switch (efetivo) {
    case 'ATIVA':
      return ApresentacaoStatus('Ativa', AppColors.successText, AppColors.successBg);
    case 'AGENDADA':
      return ApresentacaoStatus('Agendada', AppColors.warningText, AppColors.warningBg);
    case 'VENCIDA':
      return ApresentacaoStatus('Vencida', AppColors.textMuted, AppColors.surface);
    default:
      return ApresentacaoStatus('Encerrada', AppColors.textMuted, AppColors.surface);
  }
}

/// Data (AAAA-MM-DD...) no formato dd/mm/aaaa. Datas de calendário vêm da API
/// como meia-noite UTC; `created_at` é um instante e precisa ir pro horário
/// local antes de virar data (senão, à noite, mostra o dia seguinte).
String formatarData(String bruta, {bool instante = false}) {
  var d = DateTime.parse(bruta);
  if (instante) d = d.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
