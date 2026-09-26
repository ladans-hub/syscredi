import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/infrastructure/guest_repository.dart';

void main() {
  test('visitante é isolado, não privilegiado e somente leitura', () async {
    const repository = GuestRepository();
    final profile = Map<String, dynamic>.from(await repository.get('/me'));
    expect(profile['role'], 'operator');
    expect(profile['guest'], isTrue);
    expect(await repository.get('/clients?limit=50'), isEmpty);
    await expectLater(
      repository.write('POST', '/clients', {'name': 'Teste'}),
      throwsA(
        isA<ApiFailure>()
            .having((error) => error.status, 'status', 403)
            .having(
              (error) => error.message,
              'message',
              contains('somente leitura'),
            ),
      ),
    );
  });
}
