import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Campo de cor livre (RGB + HEX) — usado em Configurações pra loja escolher
/// a cor principal/destaque da marca, sem se limitar a uma paleta fixa.
class ColorPickerField extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  const ColorPickerField({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
  });

  static int _canal8bit(double v) => (v * 255.0).round().clamp(0, 255);

  static String hexDe(Color c) {
    String h(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${h(_canal8bit(c.r))}${h(_canal8bit(c.g))}${h(_canal8bit(c.b))}';
  }

  Future<void> _abrirSeletor(BuildContext context) async {
    final resultado = await showDialog<Color>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ColorPickerDialog(corInicial: color),
    );
    if (resultado != null) onChanged(resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _abrirSeletor(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.inputBg,
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 10),
                Text(hexDe(color),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const Spacer(),
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color corInicial;
  const _ColorPickerDialog({required this.corInicial});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late int _r;
  late int _g;
  late int _b;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _r = ColorPickerField._canal8bit(widget.corInicial.r);
    _g = ColorPickerField._canal8bit(widget.corInicial.g);
    _b = ColorPickerField._canal8bit(widget.corInicial.b);
    _hexController = TextEditingController(text: ColorPickerField.hexDe(widget.corInicial));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _aplicarHexDigitado(String value) {
    final limpo = value.replaceAll('#', '').trim();
    if (limpo.length != 6) return;
    final parsed = int.tryParse(limpo, radix: 16);
    if (parsed == null) return;
    setState(() {
      _r = (parsed >> 16) & 0xFF;
      _g = (parsed >> 8) & 0xFF;
      _b = parsed & 0xFF;
    });
  }

  void _sincronizarHexComSliders() {
    _hexController.text = ColorPickerField.hexDe(Color.fromARGB(255, _r, _g, _b));
  }

  @override
  Widget build(BuildContext context) {
    final corAtual = Color.fromARGB(255, _r, _g, _b);
    return AlertDialog(
      title: const Text('Escolher cor'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: corAtual,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                labelText: 'Código hexadecimal',
                hintText: '#RRGGBB',
              ),
              onChanged: _aplicarHexDigitado,
            ),
            const SizedBox(height: 12),
            _campoSlider('R', _r, const Color(0xFFD32F2F), (v) {
              setState(() {
                _r = v;
                _sincronizarHexComSliders();
              });
            }),
            _campoSlider('G', _g, const Color(0xFF2E7D32), (v) {
              setState(() {
                _g = v;
                _sincronizarHexComSliders();
              });
            }),
            _campoSlider('B', _b, const Color(0xFF1565C0), (v) {
              setState(() {
                _b = v;
                _sincronizarHexComSliders();
              });
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(corAtual),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _campoSlider(String label, int value, Color corTrilha, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: corTrilha,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 32, child: Text(value.toString(), textAlign: TextAlign.end)),
      ],
    );
  }
}
