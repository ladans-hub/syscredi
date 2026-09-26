import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/simulator_panel.dart';

class SimulatorRepository implements Repository {
  @override
  Future<dynamic> get(String path) async => [
    {
      'id': 'standard',
      'name': 'Crédito parcelado',
      'code': 'PARCELADO',
      'active': true,
      'annual_rate_bps': 2400,
      'rate_period': 'annual',
      'interest_method': 'declining_balance',
      'payment_frequency': 'monthly',
      'min_amount_cents': 1000000,
      'max_amount_cents': 5000000,
      'min_months': 6,
      'max_months': 12,
      'fees': const [],
    },
    {
      'id': 'quick',
      'name': 'Crédito rápido',
      'code': 'CREDITO-RAPIDO',
      'active': true,
      'annual_rate_bps': 500,
      'rate_period': 'monthly',
      'interest_method': 'flat',
      'payment_frequency': 'monthly',
      'min_amount_cents': 500000,
      'max_amount_cents': 2000000,
      'min_months': 1,
      'max_months': 1,
      'fees': [
        {'name': 'Taxa de abertura', 'percentage': 2},
      ],
    },
  ];

  @override
  Future<dynamic> write(String method, String path, Json body) =>
      throw UnimplementedError();
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

void main() {
  testWidgets('simulador usa características do Crédito rápido', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SimulatorPanel(repository: SimulatorRepository())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crédito rápido'), findsOneWidget);
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields.any((field) => field.controller?.text == '1'), isTrue);
    expect(fields.any((field) => field.controller?.text == '5.00'), isTrue);
    expect(fields.any((field) => field.controller?.text == '2.00'), isTrue);
    expect(find.text('Juro flat'), findsOneWidget);
    expect(find.text('1 prestações previstas'), findsOneWidget);
  });

  testWidgets('Crédito rápido aplica 20% para prazo de até 14 dias', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SimulatorPanel(repository: SimulatorRepository())),
      ),
    );
    await tester.pumpAndSettle();

    final capital = find.widgetWithText(TextFormField, 'Capital');
    await tester.enterText(capital, '4000');
    await tester.tap(find.text('Curto prazo'));
    await tester.pumpAndSettle();

    expect(find.text('20.00'), findsOneWidget);
    expect(find.text('4 800,00 MT'), findsWidgets);
    expect(find.text('800,00 MT'), findsWidgets);
    expect(find.text('1 prestações previstas'), findsOneWidget);
  });
}
