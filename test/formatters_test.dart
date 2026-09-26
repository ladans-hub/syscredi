import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/formatters.dart';
import 'package:syscredi/features/api/domain/money.dart';

void main() {
  test('dinheiro usa milhares, vírgula e duas casas', () {
    expect(money(520000), '5 200,00 MT');
    expect(money(123456789), '1 234 567,89 MT');
    expect(money(-5134), '-51,34 MT');
  });

  test('telefone moçambicano usa indicativo e agrupamento', () {
    expect(formatPhone('841234567'), '+258 84 123 4567');
    expect(formatPhone('+258841234567'), '+258 84 123 4567');
    expect(formatPhone('258 84 123 4567'), '+258 84 123 4567');
    expect(formatPhone(null), '—');
  });
}
