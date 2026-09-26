import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/credit_stages.dart';

class RecordingRepository implements Repository {
  RecordingRepository({
    this.requestStages = const ['analysis'],
    this.paymentAccountId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    this.paymentAccountUsesSnakeCase = false,
    this.paymentAccountUsesValue = false,
    this.requestUsesSnakeCaseId = false,
  });
  List<String> requestStages;
  final String paymentAccountId;
  final bool paymentAccountUsesSnakeCase;
  final bool paymentAccountUsesValue;
  final bool requestUsesSnakeCaseId;
  final writes = <({String method, String path, Json body})>[];

  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/loans')) {
      return [
        {
          'id': '33333333-3333-3333-3333-333333333333',
          'version': 4,
          'number': 'LN-2026-0001',
          'client_name': 'Cliente Teste',
          'principal_cents': 1250000,
          'balance_cents': 1250000,
          'months': 6,
          'status': 'active',
          'currency': 'MZN',
        },
      ];
    }
    if (path.startsWith('/requests')) {
      return [
        for (final (index, stage) in requestStages.indexed)
          {
            'id': requestUsesSnakeCaseId
                ? 'CR-PUBLIC-${index + 1}'
                : 'cccccccc-cccc-4ccc-8ccc-${(index + 1).toString().padLeft(12, '0')}',
            if (requestUsesSnakeCaseId)
              'request_id':
                  'dddddddd-dddd-4ddd-8ddd-${(index + 1).toString().padLeft(12, '0')}',
            'version': 7,
            'number': 'CR-2026-030${index + 3}',
            'client_name': index == 0 ? 'Dina' : 'Cliente ${index + 1}',
            'product_name': 'Produto Teste',
            'amount_cents': 1250000,
            'months': 6,
            'stage': stage,
          },
      ];
    }
    if (path.startsWith('/clients')) {
      return [
        {'id': 'BI 041102314433B', 'name': 'Cliente legado inválido'},
        {
          'id': 'CLIENTE-001',
          'client_id': '11111111-1111-1111-1111-111111111111',
          'name': 'Cliente Teste',
        },
        {
          'id': 'CLIENTE-002',
          'clientId': '22222222-2222-2222-2222-222222222222',
          'name': 'Segundo Cliente',
        },
      ];
    }
    if (path.startsWith('/users')) {
      return [
        {'id': 'user-1', 'name': 'Gestor', 'role': 'manager'},
      ];
    }
    if (path.startsWith('/payment-accounts')) {
      return [
        {
          paymentAccountUsesValue
                  ? 'value'
                  : paymentAccountUsesSnakeCase
                  ? 'account_id'
                  : 'id':
              paymentAccountId,
          'name': 'Caixa',
          'currency': 'MZN',
        },
      ];
    }
    if (path.startsWith('/products')) {
      return [
        {
          'id': 'product-standard',
          'name': 'Produto Teste',
          'active': true,
          'min_months': 6,
          'max_months': 12,
        },
        {
          'id': 'product-1',
          'name': 'Crédito rápido',
          'code': 'CREDITO-RAPIDO',
          'active': true,
          'min_months': 1,
          'max_months': 1,
        },
      ];
    }
    return <Json>[];
  }

  @override
  Future<dynamic> write(String method, String path, Json body) async {
    writes.add((method: method, path: path, body: body));
    if (method == 'PATCH' &&
        path.endsWith('/stage') &&
        body['stage'] is String &&
        requestStages.isNotEmpty) {
      requestStages = [body['stage'] as String, ...requestStages.skip(1)];
    }
    return <String, dynamic>{};
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
}

Future<RecordingRepository> openStage(
  WidgetTester tester,
  String stage, {
  String requestStage = 'analysis',
  List<String>? requestStages,
  String role = 'manager',
  String paymentAccountId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
  bool paymentAccountUsesSnakeCase = false,
  bool paymentAccountUsesValue = false,
  bool requestUsesSnakeCaseId = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repository = RecordingRepository(
    requestStages: requestStages ?? [requestStage],
    paymentAccountId: paymentAccountId,
    paymentAccountUsesSnakeCase: paymentAccountUsesSnakeCase,
    paymentAccountUsesValue: paymentAccountUsesValue,
    requestUsesSnakeCaseId: requestUsesSnakeCaseId,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CreditStagesView(
          stage: stage,
          repository: repository,
          role: role,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> submitStageForm(WidgetTester tester) async {
  final button = find.text('Guardar e continuar');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('financiamento aceita o identificador retornado pela API', (
    tester,
  ) async {
    final repository = await openStage(tester, 'financing');

    await tester.tap(find.text('Novo financiamento'));
    await tester.pumpAndSettle();
    expect(find.text('Cliente legado inválido'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>),
        matching: find.text('Crédito rápido'),
      ),
      findsOneWidget,
    );
    final term = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Prazo (meses)'),
    );
    expect(term.controller?.text, '1');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(repository.writes.single.path, '/requests');
    expect(
      repository.writes.single.body['clientId'],
      '11111111-1111-1111-1111-111111111111',
    );
    expect(repository.writes.single.body['productId'], 'product-1');
  });

  testWidgets('financiamento aceita cliente escolhido no selector', (
    tester,
  ) async {
    final repository = await openStage(tester, 'financing');

    await tester.tap(find.text('Novo financiamento'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(InputDecorator),
        matching: find.text('Cliente Teste'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Segundo Cliente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Seleccione um cliente válido.'), findsNothing);
    expect(repository.writes, hasLength(1));
    expect(
      repository.writes.single.body['clientId'],
      '22222222-2222-2222-2222-222222222222',
    );
  });

  testWidgets('análise usa endpoint especializado suportado pela API', (
    tester,
  ) async {
    final repository = await openStage(tester, 'financial-analysis');

    await tester.tap(find.text('Nova análise'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(
      repository.writes.single.path,
      '/requests/cccccccc-cccc-4ccc-8ccc-000000000001/financial-analysis',
    );
    expect(repository.writes.single.body['version'], 7);
    expect(repository.writes.single.body['opinion'], 'favourable');
  });

  testWidgets('autorização usa transição suportada pela API', (tester) async {
    final repository = await openStage(
      tester,
      'credit-authorization',
      requestStage: 'approved',
    );

    await tester.tap(find.text('Nova autorização'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(
      repository.writes.single.path,
      '/requests/cccccccc-cccc-4ccc-8ccc-000000000001/authorization',
    );
    expect(repository.writes.single.body, {
      'decision': 'authorized',
      'version': 7,
    });
  });

  testWidgets('desembolso envia apenas a conta aceita pela API', (
    tester,
  ) async {
    final repository = await openStage(
      tester,
      'credit-disbursement',
      requestStage: 'approved',
    );

    await tester.tap(find.text('Preparar desembolso'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(
      repository.writes.single.path,
      '/requests/cccccccc-cccc-4ccc-8ccc-000000000001/disburse',
    );
    expect(repository.writes.single.body, {
      'accountId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    });
  });

  testWidgets('desembolso aceita UUID alternativo da conta', (tester) async {
    final repository = await openStage(
      tester,
      'credit-disbursement',
      requestStage: 'approved',
      paymentAccountId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      paymentAccountUsesSnakeCase: true,
    );

    await tester.tap(find.text('Preparar desembolso'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(
      repository.writes.single.body['accountId'],
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
  });

  testWidgets('desembolso aceita UUID da conta no campo value', (tester) async {
    final repository = await openStage(
      tester,
      'credit-disbursement',
      requestStage: 'approved',
      paymentAccountId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      paymentAccountUsesValue: true,
    );

    await tester.tap(find.text('Preparar desembolso'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(
      repository.writes.single.body['accountId'],
      'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
    );
  });

  testWidgets('desembolso usa UUID alternativo do pedido', (tester) async {
    final repository = await openStage(
      tester,
      'credit-disbursement',
      requestStage: 'approved',
      requestUsesSnakeCaseId: true,
    );

    await tester.tap(find.text('Preparar desembolso'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(
      repository.writes.single.path,
      '/requests/dddddddd-dddd-4ddd-8ddd-000000000001/disburse',
    );
  });

  testWidgets('desembolso lista apenas clientes aptos', (tester) async {
    await openStage(
      tester,
      'credit-disbursement',
      requestStages: const ['approved', 'analysis', 'committee'],
    );

    await tester.tap(find.text('Preparar desembolso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CR-2026-0303 · Dina'));
    await tester.pumpAndSettle();

    expect(find.text('CR-2026-0303 · Dina'), findsWidgets);
    expect(find.text('CR-2026-0304 · Cliente 2'), findsNothing);
    expect(find.text('CR-2026-0305 · Cliente 3'), findsNothing);
    expect(find.text('Cliente Teste'), findsNothing);
    expect(find.text('Segundo Cliente'), findsNothing);
  });

  testWidgets('reestruturação envia plano válido para loan-adjustments', (
    tester,
  ) async {
    final repository = await openStage(tester, 'credit-restructuring');

    await tester.tap(find.text('Nova reestruturação'));
    await tester.pumpAndSettle();
    await submitStageForm(tester);

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(repository.writes.single.path, '/loan-adjustments');
    expect(
      repository.writes.single.body['loanId'],
      '33333333-3333-3333-3333-333333333333',
    );
    final snapshot = Map<String, dynamic>.from(
      repository.writes.single.body['newSnapshot'] as Map,
    );
    final schedule = List<Map<String, dynamic>>.from(
      (snapshot['schedule'] as List).map(
        (row) => Map<String, dynamic>.from(row as Map),
      ),
    );
    expect(schedule, hasLength(9));
    expect(
      schedule.fold<int>(0, (sum, row) => sum + (row['principalCents'] as int)),
      1250000,
    );
    expect(schedule.first, containsPair('dueDate', '2026-10-01'));
    expect(schedule.last['number'], 9);
  });

  testWidgets('aprovação mostra apenas processos em comité', (tester) async {
    await openStage(
      tester,
      'credit-approval',
      requestStages: const [
        'documentation',
        'analysis',
        'committee',
        'approved',
      ],
    );

    expect(find.text('CR-2026-0305'), findsOneWidget);
    expect(find.text('CR-2026-0303'), findsNothing);
    expect(find.text('CR-2026-0304'), findsNothing);
    expect(find.text('CR-2026-0306'), findsNothing);
    expect(find.text('Em comité'), findsOneWidget);
  });

  testWidgets('operador não pode avançar processo em comité', (tester) async {
    await openStage(
      tester,
      'credit-approval',
      requestStage: 'committee',
      role: 'operator',
    );

    await tester.tap(find.text('CR-2026-0303'));
    await tester.pumpAndSettle();

    expect(find.text('Avançar processo'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('avançar persiste transição e remove processo da fila', (
    tester,
  ) async {
    final repository = await openStage(
      tester,
      'financial-analysis',
      requestStage: 'analysis',
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avançar etapa'));
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'PATCH');
    expect(
      repository.writes.single.path,
      '/requests/cccccccc-cccc-4ccc-8ccc-000000000001/stage',
    );
    expect(repository.writes.single.body['stage'], 'committee');
    expect(repository.writes.single.body['version'], 7);
  });

  testWidgets('financiamento mostra somente pedidos em documentação', (
    tester,
  ) async {
    await openStage(
      tester,
      'financing',
      requestStages: const ['documentation', 'analysis'],
    );

    expect(find.text('CR-2026-0303'), findsOneWidget);
    expect(find.text('CR-2026-0304'), findsNothing);
    expect(find.text('Documentação'), findsOneWidget);
    expect(find.text('Em análise'), findsNothing);
  });

  testWidgets('processo avançado sai da fila de financiamento', (tester) async {
    await openStage(
      tester,
      'financing',
      requestStages: const ['documentation', 'documentation'],
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Pesquisar cliente ou referência'),
      'dina',
    );
    await tester.pumpAndSettle();
    expect(find.text('CR-2026-0303'), findsOneWidget);
    expect(find.text('CR-2026-0304'), findsNothing);

    await tester.tap(find.text('CR-2026-0303'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avançar processo'));
    await tester.pumpAndSettle();

    expect(find.text('CR-2026-0303'), findsNothing);
    expect(find.text('Detalhe do processo CR-2026-0303'), findsNothing);
    expect(find.text('CR-2026-0304'), findsOneWidget);
    final search = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Pesquisar cliente ou referência'),
    );
    expect(search.controller?.text, isEmpty);
  });

  testWidgets('arquivar exige motivo e persiste rejeição terminal', (
    tester,
  ) async {
    final repository = await openStage(
      tester,
      'financial-analysis',
      requestStage: 'analysis',
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arquivar processo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Cliente desistiu');
    await tester.tap(find.text('Arquivar'));
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'PATCH');
    expect(
      repository.writes.single.path,
      '/requests/cccccccc-cccc-4ccc-8ccc-000000000001/stage',
    );
    expect(repository.writes.single.body, {
      'stage': 'rejected',
      'reason': 'Cliente desistiu',
      'version': 7,
    });
  });
}
