import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/portfolio_views.dart';

class CollectionsRepository implements Repository {
  @override
  Future<dynamic> get(String path) async {
    if (path.startsWith('/loans?')) {
      return [
        {
          'id': 'loan-1',
          'number': 'CTR-2026-001',
          'client_name': 'Dina Paulo Mondlane',
        },
      ];
    }
    if (path == '/loans/loan-1/installments') {
      return [
        {
          'number': 1,
          'due_date': '2026-09-24',
          'principal_cents': 400000,
          'interest_cents': 120000,
          'paid_cents': 0,
          'remaining_cents': 520000,
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
  Future<dynamic> write(String method, String path, Json body) =>
      throw UnimplementedError();
}

void main() {
  testWidgets('cobranças mostra prestações e saldo reais', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CollectionsView(repository: CollectionsRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);
    expect(find.text('CTR-2026-001'), findsOneWidget);
    expect(find.text('5 200,00 MT'), findsWidgets);
    expect(find.text('Vence hoje'), findsWidgets);
  });

  testWidgets('pesquisa cobranças por cliente e contrato sem acentos', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CollectionsView(repository: CollectionsRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mondlane');
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'prestacao 1');
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '5 200');
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsNothing);
    expect(find.text('Não existem prestações pendentes.'), findsOneWidget);

    await tester.tap(find.byTooltip('Limpar pesquisa'));
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Limpar'));
    await tester.pump();
    expect(find.text('Dina Paulo Mondlane'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}
