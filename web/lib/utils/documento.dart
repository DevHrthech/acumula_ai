import 'package:flutter/services.dart';

/// Documento da empresa: CPF (pessoa física) ou CNPJ (pessoa jurídica).
/// Mesmas regras de server/src/utils/documento.js — o servidor é quem decide;
/// aqui a validação só evita ida e volta à API e mostra o selo "Válido".
enum TipoDocumento { cnpj, cpf }

extension TipoDocumentoTexto on TipoDocumento {
  String get rotulo => this == TipoDocumento.cpf ? 'CPF' : 'CNPJ';
  String get mascaraExemplo => this == TipoDocumento.cpf ? '000.000.000-00' : '00.000.000/0000-00';
  int get digitos => this == TipoDocumento.cpf ? 11 : 14;
}

String somenteDigitos(String valor) => valor.replaceAll(RegExp(r'\D'), '');

bool _repetidos(String d) => RegExp(r'^(\d)\1+$').hasMatch(d);

bool cpfValido(String valor) {
  final d = somenteDigitos(valor);
  if (d.length != 11 || _repetidos(d)) return false;

  int digito(String base, int pesoInicial) {
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += int.parse(base[i]) * (pesoInicial - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  final dv1 = digito(d.substring(0, 9), 10);
  final dv2 = digito('${d.substring(0, 9)}$dv1', 11);
  return d == '${d.substring(0, 9)}$dv1$dv2';
}

bool cnpjValido(String valor) {
  final d = somenteDigitos(valor);
  if (d.length != 14 || _repetidos(d)) return false;

  int digito(String base, List<int> pesos) {
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += int.parse(base[i]) * pesos[i];
    }
    final resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  final base = d.substring(0, 12);
  final dv1 = digito(base, pesos1);
  final dv2 = digito('$base$dv1', pesos2);
  return d == '$base$dv1$dv2';
}

/// Tipo deduzido pelo número de dígitos (11 = CPF, 14 = CNPJ); `null` se não
/// tem um dos dois tamanhos.
TipoDocumento? tipoDoDocumento(String valor) {
  switch (somenteDigitos(valor).length) {
    case 11:
      return TipoDocumento.cpf;
    case 14:
      return TipoDocumento.cnpj;
    default:
      return null;
  }
}

/// CPF ou CNPJ válido (dígito verificador do tipo certo).
bool documentoValido(String valor) {
  switch (tipoDoDocumento(valor)) {
    case TipoDocumento.cpf:
      return cpfValido(valor);
    case TipoDocumento.cnpj:
      return cnpjValido(valor);
    case null:
      return false;
  }
}

/// Aplica a máscara do tipo: `000.000.000-00` ou `00.000.000/0000-00`.
/// Corta o que passar do tamanho do documento.
String formatarDocumento(String valor, TipoDocumento tipo) {
  final d = somenteDigitos(valor);
  final limite = tipo.digitos;
  final c = d.length > limite ? d.substring(0, limite) : d;
  final b = StringBuffer();
  for (var i = 0; i < c.length; i++) {
    if (tipo == TipoDocumento.cpf) {
      if (i == 3 || i == 6) b.write('.');
      if (i == 9) b.write('-');
    } else {
      if (i == 2 || i == 5) b.write('.');
      if (i == 8) b.write('/');
      if (i == 12) b.write('-');
    }
    b.write(c[i]);
  }
  return b.toString();
}

/// Mostra um documento já guardado (11 ou 14 dígitos) com a máscara certa; se
/// não for nenhum dos dois, devolve o texto como veio.
String documentoParaExibir(String valor) {
  final tipo = tipoDoDocumento(valor);
  return tipo == null ? valor : formatarDocumento(valor, tipo);
}

/// Máscara pelo que já foi digitado: até 11 dígitos é CPF, acima disso CNPJ.
/// Serve onde o tipo não é escolhido antes (ex.: edição do cadastro no admin).
String formatarDocumentoAuto(String valor) {
  final d = somenteDigitos(valor);
  return formatarDocumento(valor, d.length <= 11 ? TipoDocumento.cpf : TipoDocumento.cnpj);
}

/// Formatador que decide a máscara (CPF ou CNPJ) pelo número de dígitos.
class DocumentoAutoFormatter extends TextInputFormatter {
  const DocumentoAutoFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final texto = formatarDocumentoAuto(novo.text);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Formatador de campo de texto que mantém a máscara do [tipo] enquanto digita.
class DocumentoFormatter extends TextInputFormatter {
  final TipoDocumento tipo;
  const DocumentoFormatter(this.tipo);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final texto = formatarDocumento(novo.text, tipo);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
