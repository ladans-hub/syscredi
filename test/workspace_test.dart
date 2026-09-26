import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:syscredi/features/api/infrastructure/http_repository.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/session_view_model.dart';
import 'package:syscredi/features/api/presentation/workspace.dart';
import 'package:syscredi/features/api/presentation/form.dart';
import 'api_test.dart' show MemorySecrets;

class FakeWorkspaceSession extends WorkspaceSession {
  FakeWorkspaceSession(this.api, this.profile);
  @override
  final ApiClient api;
  @override
  final Json profile;
  @override
  Future<void> updatePassword(String password) async {}

  @override
  Future<void> verify() async {
    await api.get('/me');
  }

  @override
  Future<void> logout() async {}
  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}

void main() {
  for (final role in ['operator', 'analyst', 'manager']) {
    testWidgets('área remota respeita navegação de $role', (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final profile = {
        'id': 'a',
        'name': 'Maria',
        'role': role,
        'active': true,
      };
      final api = ApiClient(
        baseUrl: 'https://api.test/v1',
        scope: 's',
        store: MemorySecrets(),
        userId: () => 'a',
        accessToken: () async => 'token',
        refreshToken: () async {},
        client: MockClient(
          (r) async => http.Response(
            jsonEncode(
              r.url.path.endsWith('/me')
                  ? profile
                  : r.url.path.endsWith('/dashboard')
                  ? {
                      'clients': '2',
                      'pending_requests': '1',
                      'outstanding_cents': '10000',
                      'overdue_cents': '0',
                    }
                  : [],
            ),
            200,
          ),
        ),
      );
      final session = FakeWorkspaceSession(api, profile);
      await tester.pumpWidget(MaterialApp(home: Workspace(session: session)));
      await tester.pumpAndSettle();
      expect(find.text('100,00 MT'), findsOneWidget);
      // The remote shell now uses the same shared navigation for every role;
      // role-specific administration remains available through permissions.
      expect(find.text('Utilizadores'), findsNothing);
      expect(find.text('Auditoria'), findsNothing);
      await tester.tap(find.byTooltip('Pesquisar'));
      await tester.pumpAndSettle();
      expect(find.text('Pesquisa'), findsOneWidget);
      expect(
        find.text('Utilizadores'),
        role == 'manager' ? findsOneWidget : findsNothing,
      );
      await tester.enterText(find.byType(TextField), 'clientes');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.widgetWithText(ListTile, 'Clientes'),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Novo cliente'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });
  }
  testWidgets('centro de notificações filtra e marca como lida', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profile = {
      'id': 'a',
      'name': 'Maria',
      'role': 'manager',
      'active': true,
    };
    var marked = false;
    var notificationLoads = 0;
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'notifications',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
      client: MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          return http.Response(jsonEncode(profile), 200);
        }
        if (request.url.path.endsWith('/dashboard')) {
          return http.Response(
            jsonEncode({
              'clients': 0,
              'active_loans': 0,
              'pending_requests': 0,
              'outstanding_cents': 0,
              'overdue_cents': 0,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/notifications/n-1/read')) {
          marked = true;
          return http.Response(
            jsonEncode({'id': 'n-1', 'read_at': '2026-09-25T00:00:00Z'}),
            200,
          );
        }
        if (request.url.path.endsWith('/notifications')) {
          notificationLoads++;
          return http.Response(
            jsonEncode([
              {
                'id': 'n-1',
                'category': 'approval',
                'title': 'Crédito para aprovação',
                'body': 'Existe um pedido aguardando decisão.',
                'created_at': '2026-09-24T20:00:00Z',
                'read_at': marked ? '2026-09-25T00:00:00Z' : null,
              },
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );
    final session = FakeWorkspaceSession(api, profile);
    await tester.pumpWidget(MaterialApp(home: Workspace(session: session)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Centro de notificações'));
    await tester.pumpAndSettle();
    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Crédito para aprovação'), findsOneWidget);
    final loadsBeforeRefresh = notificationLoads;
    await tester.tap(find.byTooltip('Actualizar'));
    await tester.pumpAndSettle();
    expect(notificationLoads, greaterThan(loadsBeforeRefresh));
    await tester.tap(find.textContaining('Novas'));
    await tester.pump();
    await tester.tap(find.text('Crédito para aprovação'));
    await tester.pumpAndSettle();
    expect(marked, isTrue);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('formulário converte montante em centavos antes do envio', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 's',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
    );
    Json? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await form(context, api, 'Pagamento', const [
                  Field('amountCents', 'Montante (MT)', kind: 'money'),
                ]);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '10,29');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(result, {'amountCents': 1029});
    api.close();
  });

  testWidgets('formulário preserva data civil ao editar um registo', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'date-edit',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
    );
    Json? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await form(context, api, 'Editar cliente', const [
                  Field(
                    'birthDate',
                    'Data de nascimento',
                    kind: 'date',
                    optional: true,
                    initial: '1990-05-20T00:00:00.000Z',
                  ),
                ]);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(result, {'birthDate': '1990-05-20'});
    api.close();
  });

  testWidgets('formulário inválido não produz payload para requisição', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'validation',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
    );
    Json? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await form(context, api, 'Cliente', const [
                  Field('name', 'Nome'),
                  Field('email', 'Email'),
                ]);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(result, isNull);
    expect(find.text('Preencha este campo.'), findsNWidgets(2));
    expect(find.byType(Dialog), findsOneWidget);
    api.close();
  });

  testWidgets('recusa sem motivo não fecha o formulário', (tester) async {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'decision-validation',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
    );
    Json? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await form(context, api, 'Decisão', const [
                  Field(
                    'stage',
                    'Decisão',
                    initial: 'rejected',
                    options: {'approved': 'Aprovar', 'rejected': 'Recusar'},
                  ),
                  Field('reason', 'Motivo', optional: true),
                ]);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(result, isNull);
    expect(find.text('Indique o motivo da recusa.'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    api.close();
  });

  testWidgets('cliente inválido é bloqueado antes de formar o payload', (
    tester,
  ) async {
    final api = ApiClient(
      baseUrl: 'https://api.test/v1',
      scope: 'client-validation',
      store: MemorySecrets(),
      userId: () => 'a',
      accessToken: () async => 'token',
      refreshToken: () async {},
    );
    Json? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await form(context, api, 'Editar cliente', const [
                  Field('name', 'Nome completo', initial: 'A'),
                  Field('phone', 'Telefone', initial: '123'),
                  Field('document', 'Documento', initial: '1'),
                  Field('activity', 'Actividade', initial: 'Comércio'),
                  Field('location', 'Localização', initial: 'Maputo'),
                  Field(
                    'dependents',
                    'Dependentes',
                    kind: 'nonNegativeInt',
                    optional: true,
                    initial: '-1',
                  ),
                ]);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(result, isNull);
    expect(find.text('Introduza um nome válido.'), findsOneWidget);
    expect(
      find.text('Introduza um telefone moçambicano válido.'),
      findsOneWidget,
    );
    expect(find.text('Introduza um documento válido.'), findsOneWidget);
    expect(
      find.text('Introduza um número inteiro igual ou superior a zero.'),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    api.close();
  });
}
