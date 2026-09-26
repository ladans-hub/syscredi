import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/risk_center_view.dart';

void main() {
  final rows = <Json>[
    {
      'client_name': 'Cliente A',
      'loan_id': 'CR-1',
      'balance_cents': 70000,
      'days_past_due': 30,
    },
    {
      'client_name': 'Cliente B',
      'loan_id': 'CR-2',
      'balance_cents': 20000,
      'days_past_due': 31,
    },
    {
      'client_name': 'Cliente C',
      'loan_id': 'CR-3',
      'balance_cents': 10000,
      'days_past_due': 91,
      'restructured': true,
    },
  ];
  Future<void> open(
    WidgetTester tester,
    List<Json> data, {
    double width = 1400,
  }) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RiskCenterView(rows: data)),
        ),
      ),
    );
  }

  testWidgets('PAR usa saldo integral e limiares estritos', (tester) async {
    await open(tester, rows);
    expect(find.text('30,0%'), findsOneWidget);
    expect(find.text('10,0%'), findsOneWidget);
    expect(find.text('1 000,00 MT'), findsOneWidget);
    await tester.tap(find.text('Apenas prioritários'));
    await tester.pumpAndSettle();
    expect(find.text('Cliente A'), findsNothing);
    expect(find.text('Cliente B'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'CR-3');
    await tester.pumpAndSettle();
    expect(find.text('Cliente B'), findsNothing);
    await tester.ensureVisible(find.byTooltip('Ver análise de risco'));
    await tester.tap(find.byTooltip('Ver análise de risco'));
    await tester.pumpAndSettle();
    expect(find.text('Análise de risco'), findsOneWidget);
    expect(
      find.text('Rever estratégia de recuperação e garantias'),
      findsOneWidget,
    );
  });

  testWidgets('Dados incompletos não produzem PAR nem saldo fictício', (
    tester,
  ) async {
    await open(tester, [
      {'client_name': 'Sem dados'},
    ]);
    expect(find.text('0,0%'), findsNothing);
    expect(find.text('0,00 MT'), findsNothing);
    expect(find.text('Dados incompletos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ecrã estreito, limpeza da pesquisa e estado vazio', (
    tester,
  ) async {
    await open(tester, rows, width: 390);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(
      find.text('Nenhum resultado para os filtros seleccionados'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Cliente A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sem avaliações apresenta estado vazio', (tester) async {
    await open(tester, []);
    expect(find.text('Sem avaliações de risco disponíveis'), findsOneWidget);
    expect(find.text('0,0%'), findsNothing);
  });
}
