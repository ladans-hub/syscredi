import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:syscredi/features/api/infrastructure/http_repository.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/domain/money.dart';
import 'package:syscredi/app/config/config.dart';

class MemorySecrets implements SecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

void main() {
  test('onboarding público envia credenciais sem Authorization', () async {
    late http.Request captured;
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'registration',
      store: MemorySecrets(),
      userId: () => null,
      accessToken: () async => null,
      refreshToken: () async {},
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"session":{"refresh_token":"r"}}', 201);
      }),
    );
    final result = await api.publicWrite('POST', '/organizations/register', {
      'managerName': 'Gestor Teste',
      'managerEmail': 'gestor@example.com',
      'organizationName': 'Instituição Teste',
      'slug': 'instituicao-teste',
      'password': 'password123',
    });
    expect(result['session']['refresh_token'], 'r');
    expect(captured.headers.containsKey('Authorization'), isFalse);
    expect(jsonDecode(captured.body)['managerEmail'], 'gestor@example.com');
    api.close();
  });
  test('transporte autenticado recusa mutação sem chave idempotente', () async {
    final transport = HttpTransport(
      baseUrl: 'https://api.test/v1',
      userId: () => 'user-a',
      accessToken: () async => 'token',
      refreshToken: () async {},
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await expectLater(
      transport.request('POST', '/clients', body: {'name': 'x'}),
      throwsA(isA<ApiFailure>()),
    );
    transport.close();
  });
  test(
    'montantes exactos; rejeita casas extra, negativos e notação científica',
    () {
      expect(moneyInput('100,01'), 10001);
      expect(moneyInput('0.29'), 29);
      expect(money('10001'), '100,01 MT');
      for (final value in ['1.001', '-1', '1e3', 'NaN']) {
        expect(() => moneyInput(value), throwsFormatException);
      }
    },
  );
  test('configuração rejeita segredos e exige HTTPS em produção', () {
    const config = AppConfig(
      apiUrl: 'http://localhost:3000/v1',
      supabaseUrl: 'https://test.supabase.co',
      publishableKey: 'sb_publishable_test',
    );
    expect(config.validate(release: false), isNull);
    expect(config.validate(release: true), isNotNull);
    expect(
      const AppConfig(
        apiUrl: 'https://api.test/v1',
        supabaseUrl: 'https://test.supabase.co',
        publishableKey: 'sb_secret_test',
      ).validate(),
      isNotNull,
    );
    final key =
        'eyJ.${base64Url.encode(utf8.encode('{"role":"service_role"}'))}.test';
    expect(
      AppConfig(
        apiUrl: 'https://api.test/v1',
        supabaseUrl: 'https://test.supabase.co',
        publishableKey: key,
      ).validate(),
      isNotNull,
    );
  });
  test(
    'intenção fica persistida antes do envio; reinício reenvia a mesma chave',
    () async {
      final store = MemorySecrets();
      String? original;
      final first = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 'a',
        store: store,
        userId: () => 'user-a',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((request) async {
          original = request.headers['Idempotency-Key'];
          expect(store.values.values.single, contains(original!));
          expect(request.headers['Authorization'], 'Bearer token');
          throw http.ClientException('server unavailable');
        }),
      );
      await expectLater(
        first.write('POST', '/payments', {'amountCents': 3000}),
        throwsA(isA<ApiFailure>()),
      );
      first.close();
      final second = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 'a',
        store: store,
        userId: () => 'user-a',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response('{"status":"unknown"}', 200);
          }
          expect(request.headers['Idempotency-Key'], original);
          expect(jsonDecode(request.body)['amountCents'], 3000);
          return http.Response('{"payment":{"id":"one"}}', 201);
        }),
      );
      final pending = await second.pending();
      expect(pending, hasLength(1));
      await expectLater(
        second.write('POST', '/payments', {'amountCents': 3000}),
        throwsA(isA<ApiFailure>()),
      );
      await second.retry(pending.single);
      expect(await second.pending(), isEmpty);
      second.close();
    },
  );
  test(
    'resposta perdida e perfil alterado: consulta resultado sem repetir escrita',
    () async {
      final store = MemorySecrets();
      final op = PendingWrite(
        key: '12345678',
        userId: 'a',
        method: 'POST',
        path: '/requests/id/disburse',
        body: {},
      );
      await store.write('syscredi.s.pending.a', jsonEncode([op.toJson()]));
      var writes = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 's',
        store: store,
        userId: () => 'a',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((r) async {
          if (r.method != 'GET') writes++;
          return http.Response(
            '{"status":"confirmed","result":{"id":"loan"}}',
            200,
          );
        }),
      );
      expect(await api.retry(op), {'id': 'loan'});
      expect(writes, 0);
      expect(await api.pending(), isEmpty);
      api.close();
    },
  );
  test(
    'fila isolada por identidade e servidor; troca de sessão não aceita resultado antigo',
    () async {
      final store = MemorySecrets();
      String actor = 'a';
      final signal = Completer<http.Response>();
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 'one',
        store: store,
        userId: () => actor,
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((_) => signal.future),
      );
      final sending = api.write('POST', '/clients', {'name': 'A'});
      final expectation = expectLater(sending, throwsA(isA<ApiFailure>()));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      actor = 'b';
      signal.complete(http.Response('{"id":"x"}', 201));
      await expectation;
      expect(await api.pending(), isEmpty);
      actor = 'a';
      expect(await api.pending(), hasLength(1));
      final other = ApiClient(
        baseUrl: 'https://other.test/v1',
        scope: 'two',
        store: store,
        userId: () => actor,
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((_) async => http.Response('{}', 200)),
      );
      expect(await other.pending(), isEmpty);
      api.close();
      other.close();
    },
  );
  test('401 renova token uma vez e preserva a chave de operação', () async {
    final keys = <String?>[];
    var refreshes = 0;
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'a',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => refreshes == 0 ? 'old' : 'new',
      refreshToken: () async {
        refreshes++;
      },
      client: MockClient((r) async {
        keys.add(r.headers['Idempotency-Key']);
        return http.Response(
          refreshes == 0 ? '{"message":"Expired"}' : '{"id":"x"}',
          refreshes == 0 ? 401 : 201,
        );
      }),
    );
    await api.write('POST', '/payments', {});
    expect(refreshes, 1);
    expect(keys[0], keys[1]);
    expect(keys[0], isNotNull);
    api.close();
  });
  test('respostas transitórias repetem a mesma operação idempotente', () async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'retry',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
      client: MockClient((request) async {
        calls++;
        if (calls < 3) return http.Response('{"message":"busy"}', 503);
        return http.Response('{"id":"ok"}', 201);
      }),
    );
    expect(await api.write('POST', '/clients', {'name': 'A'}), {'id': 'ok'});
    expect(calls, 3);
    api.close();
  });
  test(
    '409 é definitivo e não repete automaticamente com uma chave nova',
    () async {
      var calls = 0;
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 'a',
        store: MemorySecrets(),
        userId: () => 'a',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((_) async {
          calls++;
          return http.Response('{"message":"Conflito"}', 409);
        }),
      );
      await expectLater(
        api.write('PUT', '/clients/id', {'version': 1}),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 409)),
      );
      expect(calls, 1);
      expect(await api.pending(), isEmpty);
      api.close();
    },
  );
  test(
    'todos os cadastros remotos usam escrita idempotente no transporte',
    () async {
      final paths = <String>[
        'POST /clients',
        'POST /products',
        'PATCH /products/p1',
        'POST /requests',
        'PATCH /requests/r1/stage',
        'POST /accounts',
        'POST /account-transfers',
        'POST /cash-entries',
        'POST /payments',
        'POST /businesses',
        'POST /co-signers',
        'POST /client-guarantors',
        'PUT /users',
        'POST /organization-settings',
        'POST /accounting-periods/2026-08/close',
      ];
      final seen = <String>[];
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 'catalogue',
        store: MemorySecrets(),
        userId: () => 'manager-1',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient((request) async {
          seen.add('${request.method} ${request.url.path.split('/v1').last}');
          expect(request.headers['Authorization'], 'Bearer token');
          expect(request.headers['Idempotency-Key'], isNotEmpty);
          return http.Response('{}', 201);
        }),
      );
      for (final operation in paths) {
        final split = operation.split(' ');
        await api.write(split[0], split[1], {});
      }
      expect(seen, paths);
      api.close();
    },
  );
}
