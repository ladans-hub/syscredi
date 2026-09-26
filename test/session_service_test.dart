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
  Object? logoutError;
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
  Future<void> logout() async {
    session = false;
    if (logoutError case final error?) throw error;
  }

  void expire() {
    session = false;
    actor = null;
    changes.add(false);
  }
}

class _Repository implements Repository {
  Json? registration;
  ApiFailure? registrationFailure;
  @override
  Future<dynamic> publicWrite(String method, String path, Json body) async {
    registration = body;
    if (registrationFailure case final failure?) throw failure;
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

  test('cadastro explica conflito de email já existente', () async {
    final repository = _Repository()
      ..registrationFailure = const ApiFailure(
        'User with this email already exists',
        status: 409,
      );
    final service = SessionService(_Auth(), repository);

    await expectLater(
      service.register(
        'Gestor',
        'gestor@example.com',
        'password123',
        'Instituição',
      ),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.message,
          'message',
          contains('Esqueci a palavra-passe'),
        ),
      ),
    );

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

  test('logout limpa o perfil mesmo sem evento do gateway', () async {
    final auth = _Auth();
    final service = SessionService(auth, _Repository());
    await service.verify();
    var notifications = 0;
    final subscription = service.changes.listen((_) => notifications++);

    await service.logout();

    expect(service.profile, isNull);
    expect(auth.session, isFalse);
    expect(notifications, 1);
    await subscription.cancel();
    await service.dispose();
    await auth.changes.close();
  });

  test('logout limpa o perfil mesmo quando o gateway falha', () async {
    final auth = _Auth()..logoutError = StateError('logout indisponível');
    final service = SessionService(auth, _Repository());
    await service.verify();

    await expectLater(service.logout(), throwsStateError);

    expect(service.profile, isNull);
    await service.dispose();
    await auth.changes.close();
  });
}
