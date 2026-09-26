import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/app/bootstrap/auth_only_session.dart';

void main() {
  test('dados demo ficam restritos à conta configurada', () {
    expect(isDemoAccount('ladans.me@gmail.com'), isTrue);
    expect(isDemoAccount(' LADANS.ME@GMAIL.COM '), isTrue);
    expect(isDemoAccount('novo@instituicao.co.mz'), isFalse);
    expect(isDemoAccount(null), isFalse);
  });
}
