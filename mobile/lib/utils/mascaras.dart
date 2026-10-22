import 'package:flutter/services.dart';

/// Máscaras e validações dos campos de cadastro. O servidor limpa o CPF
/// (só dígitos) antes de usar; o telefone é guardado como digitado.

String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Aplica uma máscara onde cada `#` é um dígito, e o resto é literal.
/// O literal só aparece quando já há mais dígitos depois dele (apagar o
/// último dígito leva junto a pontuação, sem "travar" o cursor).
String _aplicar(String digitos, String mascara) {
  final saida = StringBuffer();
  var i = 0;
  for (final c in mascara.split('')) {
    if (i >= digitos.length) break;
    if (c == '#') {
      saida.write(digitos[i++]);
    } else {
      saida.write(c);
    }
  }
  return saida.toString();
}

class _MascaraFormatter extends TextInputFormatter {
  final String Function(String digitos) _formatar;
  final int _maxDigitos;

  const _MascaraFormatter(this._formatar, this._maxDigitos);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    var digitos = somenteDigitos(novo.text);
    if (digitos.length > _maxDigitos) digitos = digitos.substring(0, _maxDigitos);
    final texto = _formatar(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// 000.000.000-00
final TextInputFormatter cpfFormatter = _MascaraFormatter((d) => _aplicar(d, '###.###.###-##'), 11);

/// (00) 00000-0000 (celular) ou (00) 0000-0000 (fixo, enquanto tiver 10 dígitos).
final TextInputFormatter telefoneFormatter = _MascaraFormatter(
  (d) => _aplicar(d, d.length > 10 ? '(##) #####-####' : '(##) ####-#####'),
  11,
);

/// Só dígitos, com limite de tamanho (ex.: código de 6 dígitos).
List<TextInputFormatter> soDigitos(int max) => [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(max),
    ];

/// Sem espaços (e-mail).
final TextInputFormatter semEspacos = FilteringTextInputFormatter.deny(RegExp(r'\s'));

/// CPF com 11 dígitos e dígitos verificadores corretos.
bool cpfValido(String cpf) {
  final d = somenteDigitos(cpf);
  if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
  int digito(int tamanho) {
    var soma = 0;
    for (var i = 0; i < tamanho; i++) {
      soma += int.parse(d[i]) * (tamanho + 1 - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return digito(9) == int.parse(d[9]) && digito(10) == int.parse(d[10]);
}

/// Telefone brasileiro com DDD: 10 ou 11 dígitos.
bool telefoneValido(String telefone) {
  final tamanho = somenteDigitos(telefone).length;
  return tamanho == 10 || tamanho == 11;
}
