import 'package:flutter/material.dart';
import '../screens/bloqueio_screen.dart';
import '../services/biometria.dart';
import '../state/bloqueio.dart';
import '../state/cliente_session.dart';

/// Fica por cima de todo o app (entra pelo `builder` do MaterialApp): mostra a
/// [BloqueioScreen] enquanto o app estiver bloqueado e decide quando bloquear
/// de novo — ao voltar do segundo plano depois da carência, se o cliente
/// ligou o login biométrico.
class BloqueioHost extends StatefulWidget {
  final Widget child;
  const BloqueioHost({super.key, required this.child});

  @override
  State<BloqueioHost> createState() => _BloqueioHostState();
}

class _BloqueioHostState extends State<BloqueioHost> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        Bloqueio.instance.aoIrParaSegundoPlano();
      case AppLifecycleState.resumed:
        if (Bloqueio.instance.aoVoltar()) _bloquearSePreciso();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _bloquearSePreciso() async {
    final session = ClienteSessionScope.of(context);
    final ligado = session.autenticado && session.cliente?['login_biometrico'] == true;
    if (!ligado) return;
    // Sem biometria nem bloqueio de tela no aparelho não há o que exigir.
    if (!await Biometria.disponivel()) return;
    Bloqueio.instance.bloquear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Bloqueio.instance,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (Bloqueio.instance.bloqueado) const Positioned.fill(child: BloqueioScreen()),
          ],
        );
      },
    );
  }
}
