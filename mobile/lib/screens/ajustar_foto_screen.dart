import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../theme/theme_provider.dart';

/// Tela para o cliente posicionar a foto de perfil: a foto se move e amplia
/// por baixo de um círculo fixo (é assim que ela vai aparecer no app) e o que
/// estiver dentro do círculo vira a foto. Devolve os bytes de um JPEG quadrado
/// já reduzido (640 px) via `Navigator.pop`, ou null se o cliente cancelar.
class AjustarFotoScreen extends StatefulWidget {
  final Uint8List imagem;
  const AjustarFotoScreen({super.key, required this.imagem});

  @override
  State<AjustarFotoScreen> createState() => _AjustarFotoScreenState();
}

class _AjustarFotoScreenState extends State<AjustarFotoScreen> {
  final _controller = CropController();
  bool _processando = false;
  String? _erro;

  void _aoRecortar(CropResult resultado) async {
    switch (resultado) {
      case CropSuccess(:final croppedImage):
        try {
          // Reduz e converte para JPEG fora da thread da interface.
          final pronta = await compute(_prepararFoto, croppedImage);
          if (mounted) Navigator.of(context).pop(pronta);
        } catch (_) {
          if (mounted) {
            setState(() {
              _processando = false;
              _erro = 'Não foi possível preparar a foto. Tente outra imagem.';
            });
          }
        }
      case CropFailure():
        if (mounted) {
          setState(() {
            _processando = false;
            _erro = 'Não foi possível recortar a foto. Tente novamente.';
          });
        }
    }
  }

  void _confirmar() {
    setState(() {
      _processando = true;
      _erro = null;
    });
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ajustar foto'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Crop(
                image: widget.imagem,
                controller: _controller,
                onCropped: _aoRecortar,
                // Círculo fixo; quem se move é a foto (arrastar e pinçar).
                interactive: true,
                fixCropRect: true,
                withCircleUi: true,
                aspectRatio: 1,
                initialRectBuilder: InitialRectBuilder.withSizeAndRatio(size: 0.85, aspectRatio: 1),
                baseColor: Colors.black,
                maskColor: Colors.black.withValues(alpha: 0.65),
                progressIndicator: const CircularProgressIndicator(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                _erro ?? 'Arraste a foto e use dois dedos para ampliar. A parte dentro do círculo será a sua foto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _erro == null ? Colors.white70 : Colors.redAccent, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _processando ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _processando ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: theme.isDarkMode ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _processando
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: theme.isDarkMode ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text('Usar esta foto', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Roda em outro isolate (via `compute`): reduz a foto recortada para no máximo
/// 640 px e grava como JPEG — pequena para enviar (a API aceita até 1 MB) e
/// sempre num formato que a API aceita, mesmo se a origem era PNG.
Uint8List _prepararFoto(Uint8List recortada) {
  final original = img.decodeImage(recortada);
  if (original == null) throw const FormatException('imagem inválida');
  final reduzida = original.width > 640
      ? img.copyResize(original, width: 640, height: 640, interpolation: img.Interpolation.average)
      : original;
  return Uint8List.fromList(img.encodeJpg(reduzida, quality: 88));
}
