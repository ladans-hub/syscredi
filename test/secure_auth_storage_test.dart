import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/infrastructure/secure_store.dart';

class _MemoryStore implements SecretStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('removePersistedSession apaga a sessão restaurável', () async {
    final store = _MemoryStore();
    final storage = SecureAuthStorage(store, 'syscredi.test.session');
    await storage.persistSession('token-persistido');
    expect(await storage.hasAccessToken(), isTrue);

    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });
}
