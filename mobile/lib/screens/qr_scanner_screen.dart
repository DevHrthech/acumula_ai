import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/theme_provider.dart';

/// Câmera em tela cheia para ler o QR Code da loja. O QR da loja (gerado no
/// painel da Empresa) contém só o código da loja, então o valor lido volta
/// direto para quem abriu a tela (`Navigator.pop(valor)`).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _lido = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_lido) return;
    for (final codigo in captura.barcodes) {
      final valor = codigo.rawValue?.trim();
      if (valor != null && valor.isNotEmpty) {
        _lido = true;
        Navigator.of(context).pop(valor);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ler QR Code da loja'),
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, estado, _) {
              if (estado.torchState == TorchState.unavailable) return const SizedBox.shrink();
              final ligada = estado.torchState == TorchState.on;
              return IconButton(
                tooltip: ligada ? 'Desligar lanterna' : 'Ligar lanterna',
                icon: Icon(ligada ? Icons.flash_on : Icons.flash_off),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
            errorBuilder: (context, erro) {
              final negada = erro.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        negada
                            ? 'Sem permissão para usar a câmera. Ative a câmera para o Acumula Aí nas configurações do celular, ou digite o código da loja.'
                            : 'Não foi possível abrir a câmera. Digite o código da loja.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                        child: const Text('Digitar o código'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.primary, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Text(
              'Aponte a câmera para o QR Code da loja',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
