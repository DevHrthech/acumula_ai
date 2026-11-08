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

/// Situação financeira da empresa (calculada pela API em `situacao_financeira`
/// a partir da licença e da assinatura no Asaas): é o que a 2RL precisa ver
/// de relance — em teste, paga, atrasada, bloqueada ou cancelada.
ApresentacaoStatus apresentarSituacaoFinanceira(ThemeProvider theme, String? situacao) {
  switch (situacao) {
    case 'PAGA':
      return ApresentacaoStatus('Paga', theme.successText, theme.successBg);
    case 'ATIVA_MANUAL':
      return ApresentacaoStatus('Ativa', theme.successText, theme.successBg);
    case 'EM_TESTE':
      return ApresentacaoStatus('Em teste', theme.primary, theme.primary.withValues(alpha: 0.12));
    case 'ATRASADA':
      return ApresentacaoStatus('Atrasada', theme.warningText, theme.warningBg);
    case 'BLOQUEADA':
      return ApresentacaoStatus('Bloqueada', theme.danger, theme.dangerBg);
    case 'CANCELADA':
      return ApresentacaoStatus('Cancelada', theme.textMuted, theme.surface);
    default:
      return ApresentacaoStatus('Sem licença', theme.textMuted, theme.surface);
  }
}

/// Status de uma fatura (cobrança do Asaas) como a API devolve em `status`.
ApresentacaoStatus apresentarStatusCobranca(ThemeProvider theme, String status, {bool atrasada = false}) {
  if (atrasada || status == 'OVERDUE') {
    return ApresentacaoStatus('Atrasada', theme.danger, theme.dangerBg);
  }
  switch (status) {
    case 'RECEIVED':
    case 'CONFIRMED':
    case 'RECEIVED_IN_CASH':
      return ApresentacaoStatus('Paga', theme.successText, theme.successBg);
    case 'PENDING':
      return ApresentacaoStatus('Aguardando', theme.warningText, theme.warningBg);
    case 'REFUNDED':
      return ApresentacaoStatus('Estornada', theme.textMuted, theme.surface);
    case 'DELETED':
      return ApresentacaoStatus('Cancelada', theme.textMuted, theme.surface);
    default:
      return ApresentacaoStatus(status, theme.textMuted, theme.surface);
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
