import 'package:flutter/material.dart';

/// Estado do bloqueio do app por biometria. É um singleton porque o bloqueio
/// vale para o app inteiro (fica por cima de qualquer tela) e é acionado de
/// lugares sem relação entre si: abrir o app, voltar do segundo plano e sair
/// da conta.
class Bloqueio extends ChangeNotifier {
  Bloqueio._();
  static final Bloqueio instance = Bloqueio._();

  /// Navegador do app. A tela de bloqueio fica ACIMA do Navigator (entra pelo
  /// `builder` do MaterialApp), então não consegue usar `Navigator.of(context)`.
  static final GlobalKey<NavigatorState> navegadorKey = GlobalKey<NavigatorState>();

  /// Tempo em segundo plano a partir do qual o app volta bloqueado. Curto o
  /// bastante para proteger o celular largado aberto, longo o bastante para
  /// não pedir a digital toda vez que o usuário troca de app por um instante.
  static const carencia = Duration(seconds: 30);

  bool _bloqueado = false;
  bool get bloqueado => _bloqueado;

  /// Enquanto o diálogo do Android está na tela o app também "sai de cena";
  /// sem este marcador isso contaria como ir pro segundo plano e travaria de
  /// novo logo depois de desbloquear.
  bool autenticando = false;

  DateTime? _foiParaSegundoPlano;

  void bloquear() {
    if (_bloqueado) return;
    _bloqueado = true;
    notifyListeners();
  }

  void desbloquear() {
    if (!_bloqueado) return;
    _bloqueado = false;
    notifyListeners();
  }

  /// Chamado pelo observador de ciclo de vida do app.
  void aoIrParaSegundoPlano() {
    if (autenticando) return;
    _foiParaSegundoPlano ??= DateTime.now();
  }

  /// Devolve true se ficou tempo suficiente fora para exigir a biometria.
  bool aoVoltar() {
    final saiuEm = _foiParaSegundoPlano;
    _foiParaSegundoPlano = null;
    if (autenticando || saiuEm == null) return false;
    return DateTime.now().difference(saiuEm) >= carencia;
  }

  /// Sair da conta / excluir conta: some o bloqueio e o histórico de ausência.
  void limpar() {
    _foiParaSegundoPlano = null;
    autenticando = false;
    if (_bloqueado) {
      _bloqueado = false;
      notifyListeners();
    }
  }
}
