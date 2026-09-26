import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/core/localization/user_messages.dart';

void main() {
  test('preserva motivo maker-checker em respostas 403', () {
    expect(
      userMessage(
        'Maker-checker: o criador do pedido não pode aprová-lo.',
        status: 403,
      ),
      'Maker-checker: o criador do pedido não pode aprová-lo.',
    );
  });

  test('mantém mensagem genérica para 403 sem detalhe de domínio', () {
    expect(
      userMessage('Forbidden', status: 403),
      'Não possui permissão para realizar esta operação.',
    );
  });

  test('identifica o campo que contém UUID inválido', () {
    expect(
      userMessage(['accountId must be a UUID'], status: 400),
      'O campo "accountId" possui um identificador inválido. Seleccione o registo novamente e tente outra vez.',
    );
  });
}
