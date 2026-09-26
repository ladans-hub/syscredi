import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:syscredi/features/api/application/session_service.dart';
import 'package:syscredi/features/api/domain/repository.dart';

class _Auth implements AuthGateway {
  final changes = StreamController<bool>.broadcast();
  String? actor = 'manager-1';
  bool session = true;
  int recoveries = 0;
  String? adopted;
  @override
  String? get userId => actor;
  @override
  bool get hasSession => session;
  @override
  Stream<bool> get sessionChanges => changes.stream;
  @override
  Stream<bool> get passwordRecoveryChanges => const Stream.empty();
  @override
  Future<String?> accessToken() async => 'token';
  @override
  Future<void> refreshToken() async {}
  @override
  Future<void> login(String email, String password) async {}
  @override
  Future<void> recoverPassword(String email) async => recoveries++;
  @override
  Future<void> updatePassword(String password) async {}
  @override
  Future<void> register(String name, String email, String password) async {}
  @override
  Future<void> adoptSession(String refreshToken) async =>
      adopted = refreshToken;
  @override
  Future<void> logout() async => session = false;

  void expire() {
    session = false;
    actor = null;
    changes.add(false);
  }
}

class _Repository implements Repository {
  Json? registration;
  @override
  Future<dynamic> publicWrite(String method, String path, Json body) async {
    registration = body;
    return {
      'session': {'refresh_token': 'refresh-1'},
    };
  }

  @override
  Future<dynamic> get(String path) async => {
    'id': 'manager-1',
    'role': 'manager',
    'active': true,
  };
  @override
  Future<dynamic> write(String method, String path, Json body) async => {};
  @override
  Future<List<Json>> page(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async => [];
  @override
  Future<List<PendingWrite>> pending() async => [];
  @override
  Future<dynamic> retry(PendingWrite operation) async => {};
  @override
  Future<String> cancel(PendingWrite operation) async => 'cancelled';
  @override
  Future<Uint8List> bytes(String path) async => throw UnimplementedError();
  @override
  void close() {}
}

void main() {
  test('onboarding remoto envia a instituição e adopta a sessão', () async {
    final auth = _Auth();
    final repository = _Repository();
    final service = SessionService(auth, repository);
    await service.register(
      'Gestor',
      'gestor@example.com',
      'password123',
      'Acesa Microcrédito',
    );
    expect(repository.registration?['organizationName'], 'Acesa Microcrédito');
    expect(repository.registration?['clientOperationId'], isA<String>());
    expect(repository.registration?['slug'], startsWith('org-'));
    expect(auth.adopted, 'refresh-1');
    expect(service.profile?['role'], 'manager');
    await service.dispose();
  });

  test('recuperação rejeita email inválido antes do gateway', () async {
    final auth = _Auth();
    final service = SessionService(auth, _Repository());
    await expectLater(
      service.recoverPassword('invalido'),
      throwsA(isA<ApiFailure>()),
    );
    expect(auth.recoveries, 0);
    await service.recoverPassword('gestor@example.com');
    expect(auth.recoveries, 1);
    await service.dispose();
  });

  test('sessão expirada limpa o perfil e notifica o workspace', () async {
    final auth = _Auth();
    final service = SessionService(auth, _Repository());
    await service.verify();
    expect(service.profile, isNotNull);
    auth.expire();
    await Future<void>.delayed(Duration.zero);
    expect(service.profile, isNull);
    await service.dispose();
    await auth.changes.close();
  });
}
