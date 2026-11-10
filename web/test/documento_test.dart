import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acumulaai_web/utils/documento.dart';

void main() {
  group('validação', () {
    test('CPF válido, com ou sem máscara', () {
      expect(cpfValido('529.982.247-25'), isTrue);
      expect(cpfValido('52998224725'), isTrue);
      expect(documentoValido('529.982.247-25'), isTrue);
    });

    test('CPF com dígito errado ou sequência repetida é recusado', () {
      expect(cpfValido('529.982.247-26'), isFalse);
      expect(cpfValido('111.111.111-11'), isFalse);
      expect(documentoValido('111.111.111-11'), isFalse);
    });

    test('CNPJ válido e inválido', () {
      expect(cnpjValido('11.222.333/0001-81'), isTrue);
      expect(documentoValido('11222333000181'), isTrue);
      expect(cnpjValido('11.222.333/0001-82'), isFalse);
      expect(cnpjValido('11.111.111/1111-11'), isFalse);
    });

    test('tamanhos que não são de CPF nem de CNPJ são recusados', () {
      expect(documentoValido('5299822472'), isFalse);
      expect(documentoValido('1122233300018'), isFalse);
      expect(documentoValido(''), isFalse);
    });

    test('tipo deduzido pelo número de dígitos', () {
      expect(tipoDoDocumento('529.982.247-25'), TipoDocumento.cpf);
      expect(tipoDoDocumento('11.222.333/0001-81'), TipoDocumento.cnpj);
      expect(tipoDoDocumento('123'), isNull);
    });
  });

  group('máscara', () {
    test('CPF e CNPJ formatados enquanto digita, cortando o excesso', () {
      expect(formatarDocumento('5299822', TipoDocumento.cpf), '529.982.2');
      expect(formatarDocumento('52998224725', TipoDocumento.cpf), '529.982.247-25');
      expect(formatarDocumento('529982247259999', TipoDocumento.cpf), '529.982.247-25');
      expect(formatarDocumento('11222333000181', TipoDocumento.cnpj), '11.222.333/0001-81');
      expect(formatarDocumento('112223', TipoDocumento.cnpj), '11.222.3');
    });

    test('modo automático usa CPF até 11 dígitos e CNPJ acima', () {
      expect(formatarDocumentoAuto('52998224725'), '529.982.247-25');
      expect(formatarDocumento(formatarDocumentoAuto('529982247250'), TipoDocumento.cnpj), '52.998.224/7250');
      expect(formatarDocumentoAuto('11222333000181'), '11.222.333/0001-81');
    });

    test('documentoParaExibir formata o que já está guardado', () {
      expect(documentoParaExibir('52998224725'), '529.982.247-25');
      expect(documentoParaExibir('11222333000181'), '11.222.333/0001-81');
      expect(documentoParaExibir('abc'), 'abc');
    });

    test('formatadores aplicam a máscara no campo de texto', () {
      const vazio = TextEditingValue.empty;
      final cpf = const DocumentoFormatter(TipoDocumento.cpf)
          .formatEditUpdate(vazio, const TextEditingValue(text: '52998224725'));
      expect(cpf.text, '529.982.247-25');
      final auto = const DocumentoAutoFormatter()
          .formatEditUpdate(vazio, const TextEditingValue(text: '11222333000181'));
      expect(auto.text, '11.222.333/0001-81');
    });
  });
}
