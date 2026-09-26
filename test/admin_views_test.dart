import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/admin_views.dart';

class AdminRepository implements Repository {
  AdminRepository({this.includeOperator = false});
  bool includeOperator;
  final writes = <({String method, String path, Json body})>[];
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/journal')) {
      return [
        {
          'id': 'journal-1',
          'source': 'payment',
          'source_id': 'payment-1',
          'lines': [
            {'account': '1000', 'debit': 10000, 'credit': 0},
            {'account': '1200', 'debit': 0, 'credit': 10000},
          ],
          'created_at': '2026-09-24T10:00:00Z',
        },
      ];
    }
    if (path.startsWith('/sync-operations')) {
      return [
        {
          'id': 'sync-1',
          'client_operation_id': 'operation-001',
          'operation': 'payment.create',
          'payload_hash': '12345678901234567890123456789012',
          'status': 'applied',
          'created_at': '2026-09-24T10:00:00Z',
        },
      ];
    }
    if (path.startsWith('/aml-alerts')) {
      return [
        {
          'id': 'aml-1',
          'reference': 'AML-001',
          'reason': 'Operação atípica',
          'severity': 'high',
          'status': 'open',
          'created_at': '2026-09-24T10:00:00Z',
        },
      ];
    }
    if (path.startsWith('/users')) {
      return [
        {
          'id': 'user-1',
          'name': 'Maria Gestora',
          'role': 'manager',
          'active': true,
          'created_at': '2026-09-24T10:00:00Z',
        },
        if (includeOperator)
          {
            'id': 'user-2',
            'name': 'Paulo Operador',
            'role': 'operator',
            'active': true,
            'created_at': '2026-09-24T10:00:00Z',
          },
      ];
    }
    if (path.startsWith('/backup-archives')) {
      return [
        {
          'id': 'backup-1',
          'storage_key': 'backups/2026-09-24.enc',
          'checksum': '12345678901234567890123456789012',
          'size_bytes': 1048576,
          'encrypted': true,
          'status': 'available',
          'created_at': '2026-09-24T10:00:00Z',
        },
      ];
    }
    return <dynamic>[];
  }

  @override
  Future<Uint8List> bytes(String path) => throw UnimplementedError();
  @override
  Future<String> cancel(PendingWrite operation) => throw UnimplementedError();
  @override
  void close() {}
  @override
  Future<List<Json>> page(String path, {int offset = 0, int limit = 50}) =>
      throw UnimplementedError();
  @override
  Future<List<PendingWrite>> pending() async => [];
  @override
  Future<dynamic> publicWrite(String method, String path, Json body) =>
      throw UnimplementedError();
  @override
  Future<dynamic> retry(PendingWrite operation) => throw UnimplementedError();
  @override
  Future<dynamic> write(String method, String path, Json body) async {
    writes.add((method: method, path: path, body: body));
    if (method == 'DELETE' && path == '/users/user-2') {
      includeOperator = false;
    }
    return {};
  }
}

void main() {
  const titles = {
    'accounting': 'Contabilidade',
    'sync': 'Sincronização',
    'aml': 'Alertas AML',
    'users': 'Utilizadores',
    'backup': 'Cópias de segurança',
  };

  for (final entry in titles.entries) {
    testWidgets('administração carrega ${entry.value}', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminView(
                kind: entry.key,
                repository: AdminRepository(),
                canManage: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Registos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pesquisa filtra utilizadores', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminView(
              kind: 'users',
              repository: AdminRepository(),
              canManage: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Maria Gestora'), findsOneWidget);
    expect(find.text('Nome, email, perfil ou estado'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'gestor');
    await tester.pump();
    expect(find.text('Maria Gestora'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Maria Gestora'), findsNothing);
    expect(find.textContaining('Nenhum registo encontrado'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pump();
    expect(find.text('Maria Gestora'), findsOneWidget);
  });

  testWidgets('permite remover não-Gestor e protege Gestor', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = AdminRepository(includeOperator: true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdminView(
              kind: 'users',
              repository: repository,
              canManage: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remover utilizador'), findsOneWidget);
    await tester.tap(find.byTooltip('Remover utilizador'));
    await tester.pumpAndSettle();
    expect(find.text('Remover utilizador?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Remover utilizador'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'DELETE');
    expect(repository.writes.single.path, '/users/user-2');
    expect(repository.writes.single.body, isEmpty);
    expect(find.text('Paulo Operador'), findsNothing);
    if (find.text('Fechar').evaluate().isNotEmpty) {
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    }
  });
}
