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
}
