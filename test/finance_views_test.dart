import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/finance_views.dart';

class FinanceRepository implements Repository {
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/accounts')) {
      return [
        {
          'id': '70000000-0000-0000-0000-000000000001',
          'name': 'Caixa principal',
          'currency': 'MZN',
          'balance_cents': 130000,
          'active': true,
        },
      ];
    }
    if (path.startsWith('/payments')) {
      return [
        {
          'id': '80000000-0000-0000-0000-000000000001',
          'loan_id': '60000000-0000-0000-0000-000000000001',
          'account_id': '70000000-0000-0000-0000-000000000001',
          'amount_cents': 30000,
          'method': 'mpesa',
          'created_at': '2026-09-23T09:25:42Z',
        },
      ];
    }
    if (path.startsWith('/cash-entries')) {
      return [
        {
          'account_id': '70000000-0000-0000-0000-000000000001',
          'amount_cents': 30000,
          'source': 'payment',
          'created_at': '2026-09-23T09:25:42Z',
        },
        {
          'account_id': '70000000-0000-0000-0000-000000000001',
          'amount_cents': -5000,
          'source': 'manual.withdrawal',
          'created_at': '2026-09-24T09:25:42Z',
        },
      ];
    }
    if (path.startsWith('/loans?')) {
      return [
        {
          'id': '60000000-0000-0000-0000-000000000001',
          'client_name': 'Maria José Cossa',
          'principal_cents': 100000,
          'status': 'active',
          'created_at': '2026-09-23T09:25:42Z',
        },
      ];
    }
    if (path.contains('/installments')) {
      return [
        {
          'number': 1,
          'due_date': '2026-09-20',
          'principal_cents': 10000,
          'interest_cents': 1000,
          'paid_cents': 0,
          'remaining_cents': 11000,
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
  Future<dynamic> write(String method, String path, Json body) async => {};
}

void main() {
  for (final area in const [
    'Saldos',
    'Estornos',
    'Receitas',
    'Despesas',
    'Desembolsos',
    'Reembolsos',
    'Prestações Vencidas',
    'Ativos',
  ]) {
    testWidgets('financeiro carrega $area com dados reais', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceView(area: area, repository: FinanceRepository()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = switch (area) {
        'Ativos' => 'Ativos financeiros',
        'Prestações Vencidas' => 'Prestações vencidas',
        _ => area,
      };
      expect(find.text(title), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
