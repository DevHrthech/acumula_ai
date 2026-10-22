import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

enum ResultadoBiometria {
  /// O usuário se identificou (digital, rosto ou, na falta, PIN/padrão do aparelho).
  ok,

  /// Cancelou, errou ou o sistema interrompeu — pode tentar de novo.
  falhou,

  /// O aparelho não tem como pedir identificação (sem biometria cadastrada nem
  /// bloqueio de tela). Não adianta tentar de novo.
  indisponivel,
}

/// Verificação de identidade do próprio Android (BiometricPrompt). O app só
/// recebe "passou" ou "não passou" — nunca a digital, o rosto ou o PIN.
class Biometria {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const _mensagens = <AuthMessages>[
    AndroidAuthMessages(
      signInTitle: 'Confirme sua identidade',
      cancelButton: 'Cancelar',
    ),
  ];

  /// O aparelho consegue pedir digital/rosto (ou o bloqueio de tela)?
  static Future<bool> disponivel() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<ResultadoBiometria> autenticar(String motivo) async {
    try {
      final passou = await _auth.authenticate(localizedReason: motivo, authMessages: _mensagens);
      return passou ? ResultadoBiometria.ok : ResultadoBiometria.falhou;
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          return ResultadoBiometria.indisponivel;
        default:
          return ResultadoBiometria.falhou;
      }
    } catch (_) {
      return ResultadoBiometria.falhou;
    }
  }
}
