import 'package:flutter/material.dart';
import '../services/cliente_api.dart';
import '../state/cliente_session.dart';
import '../theme/theme_provider.dart';
import 'qr_scanner_screen.dart';

/// Tela "Buscar" do bottom nav — vínculo do cliente a uma loja via código.
/// Dois caminhos: tocar no visor para ler o QR Code da loja com a câmera, ou
/// digitar o código divulgado pela loja e confirmar.
class VincularLojaScreen extends StatefulWidget {
  const VincularLojaScreen({super.key});

  @override
  State<VincularLojaScreen> createState() => _VincularLojaScreenState();
}

class _VincularLojaScreenState extends State<VincularLojaScreen> {
  final _codigoController = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _lerQr() async {
    FocusScope.of(context).unfocus();
    final lido = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (lido == null || !mounted) return;
    _codigoController.text = lido;
    await _vincular();
  }

  Future<void> _vincular() async {
    FocusScope.of(context).unfocus();
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erro = 'Digite o código da loja.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final session = ClienteSessionScope.of(context);
      final vinculo = await session.vincularLoja(codigo);
      if (!mounted) return;
      final nomeLoja = (vinculo['empresa'] as Map)['nome'] as String;
      _codigoController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vinculado a $nomeLoja com sucesso!')),
      );
    } on ClienteApiException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Não foi possível conectar à API.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return ListenableBuilder(
      listenable: theme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vincular a uma loja',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leia o QR Code da loja ou digite o código divulgado por ela',
                    style: TextStyle(fontSize: 13, color: theme.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: _carregando ? null : _lerQr,
                      child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          for (final alinhamento in [
                            Alignment.topLeft,
                            Alignment.topRight,
                            Alignment.bottomLeft,
                            Alignment.bottomRight,
                          ])
                            Align(
                              alignment: alinhamento,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: _cantoMira(theme, alinhamento),
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 44,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Toque para ler\no QR Code da loja',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('digite o código', style: TextStyle(fontSize: 12.5, color: theme.textMuted)),
                      ),
                      Expanded(child: Divider(color: theme.border)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Código da loja',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.textDark),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codigoController,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: theme.textDark, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: 'Ex: BELA2K91',
                      hintStyle: TextStyle(color: theme.textHint),
                      filled: true,
                      fillColor: theme.surface,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.primary, width: 1.5),
                      ),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _carregando ? null : _vincular,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _carregando
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: theme.isDarkMode ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text('Vincular', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cantoMira(ThemeProvider theme, Alignment alinhamento) {
    final vertical = alinhamento.y < 0
        ? BorderSide(color: theme.primary, width: 4)
        : BorderSide.none;
    final verticalBottom = alinhamento.y > 0
        ? BorderSide(color: theme.primary, width: 4)
        : BorderSide.none;
    final horizontalLeft = alinhamento.x < 0
        ? BorderSide(color: theme.primary, width: 4)
        : BorderSide.none;
    final horizontalRight = alinhamento.x > 0
        ? BorderSide(color: theme.primary, width: 4)
        : BorderSide.none;

    return SizedBox(
      width: 32,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: vertical,
            bottom: verticalBottom,
            left: horizontalLeft,
            right: horizontalRight,
          ),
        ),
      ),
    );
  }
}
