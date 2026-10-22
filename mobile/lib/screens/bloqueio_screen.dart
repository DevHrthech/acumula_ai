import 'package:flutter/material.dart';
import '../services/biometria.dart';
import '../state/bloqueio.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'login_screen.dart';

/// Tela que cobre o app inteiro quando o login biométrico está ligado e o app
/// foi aberto (ou ficou um tempo em segundo plano). Pede a digital/rosto
/// sozinha ao aparecer; se o usuário cancelar, pode tentar de novo ou sair da
/// conta. Nunca derruba a sessão por conta própria.
class BloqueioScreen extends StatefulWidget {
  const BloqueioScreen({super.key});

  @override
  State<BloqueioScreen> createState() => _BloqueioScreenState();
}

class _BloqueioScreenState extends State<BloqueioScreen> {
  bool _verificando = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    // Depois do primeiro frame: o diálogo do Android precisa da tela já montada.
    WidgetsBinding.instance.addPostFrameCallback((_) => _desbloquear());
  }

  Future<void> _desbloquear() async {
    if (_verificando) return;
    setState(() {
      _verificando = true;
      _aviso = null;
    });
    final bloqueio = Bloqueio.instance;
    bloqueio.autenticando = true;
    ResultadoBiometria resultado;
    try {
      resultado = await Biometria.autenticar('Confirme sua identidade para abrir o Acumula Aí');
    } finally {
      bloqueio.autenticando = false;
    }
    if (!mounted) return;

    switch (resultado) {
      case ResultadoBiometria.ok:
      case ResultadoBiometria.indisponivel:
        // Sem biometria nem bloqueio de tela no aparelho não há como exigir
        // nada: libera (e o usuário pode desligar a opção nas Configurações).
        bloqueio.desbloquear();
      case ResultadoBiometria.falhou:
        setState(() {
          _verificando = false;
          _aviso = 'Não foi possível confirmar sua identidade.';
        });
    }
  }

  void _sair() {
    final navigator = Bloqueio.navegadorKey.currentState;
    ClienteSessionScope.of(context).logout(); // também desfaz o bloqueio
    navigator?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    // PopScope: o botão "voltar" não pode furar o bloqueio.
    return PopScope(
      canPop: false,
      child: Material(
        color: theme.bgPage,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(Icons.fingerprint, size: 46, color: theme.primary),
                  ),
                  const SizedBox(height: 22),
                  Text('Acumula Aí', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primary)),
                  const SizedBox(height: 6),
                  Text('App bloqueado', style: TextStyle(fontSize: 14, color: theme.textMuted)),
                  if (_aviso != null) ...[
                    const SizedBox(height: 14),
                    Text(_aviso!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _verificando ? null : _desbloquear,
                      icon: const Icon(Icons.lock_open, size: 20),
                      label: const Text('Desbloquear', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _verificando ? null : _sair,
                    child: Text('Sair da conta', style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
