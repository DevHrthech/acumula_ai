import '../theme/theme_provider.dart';
import 'vigencia.dart';

/// Apresentação visual dos status de Licença/Contrato no painel admin 2RL.
/// Reaproveita `ApresentacaoStatus` (texto/cor/fundo) já usado para
/// Campanha/Promoção, mas lê as cores do tema ativo (claro/escuro).

ApresentacaoStatus apresentarStatusLicenca(ThemeProvider theme, String? status) {
  switch (status) {
    case 'ATIVA':
      return ApresentacaoStatus('Ativa', theme.successText, theme.successBg);
    case 'INADIMPLENTE':
      return ApresentacaoStatus('Inadimplente', theme.warningText, theme.warningBg);
    case 'BLOQUEADA':
      return ApresentacaoStatus('Bloqueada', theme.danger, theme.dangerBg);
    case 'CANCELADA':
      return ApresentacaoStatus('Cancelada', theme.textMuted, theme.surface);
    default:
      return ApresentacaoStatus('Sem licença', theme.textMuted, theme.surface);
  }
}

ApresentacaoStatus apresentarStatusContrato(ThemeProvider theme, String status) {
  switch (status) {
    case 'ASSINADO':
      return ApresentacaoStatus('Assinado', theme.successText, theme.successBg);
    case 'AGUARDANDO_ASSINATURA':
      return ApresentacaoStatus('Aguardando assinatura', theme.warningText, theme.warningBg);
    case 'CANCELADO':
      return ApresentacaoStatus('Cancelado', theme.danger, theme.dangerBg);
    default:
      return ApresentacaoStatus('Rascunho', theme.textMuted, theme.surface);
  }
}
