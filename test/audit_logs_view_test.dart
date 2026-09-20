import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/presentation/audit_logs_view.dart';

void main() {
  Future<void> open(WidgetTester tester, {double width = 1400}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AuditLogsView(
              rows: [
                for (var i = 0; i < 12; i++)
                  {
                    'table': 'usuarios',
                    'action': 'Login',
                    'actor_name': 'Pessoa $i',
                    'entity_id': '$i',
                    'created_at': '2026-09-11T18:00:00',
                    'description': 'Acesso $i',
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Pesquisa, paginação e detalhes do evento', (tester) async {
    await open(tester);
    expect(find.text('A mostrar 1–10 de 12 registos'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Página seguinte'));
    await tester.tap(find.byTooltip('Página seguinte'));
    await tester.pumpAndSettle();
    expect(find.text('A mostrar 11–12 de 12 registos'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Pessoa 11');
    await tester.pumpAndSettle();
    expect(find.text('A mostrar 1–1 de 1 registos'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Ver detalhes do evento'));
    await tester.tap(find.byTooltip('Ver detalhes do evento'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do evento'), findsOneWidget);
    expect(find.text('Acesso 11'), findsWidgets);
  });

  testWidgets('Ecrã estreito e pesquisa sem resultados', (tester) async {
    await open(tester, width: 390);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum registo encontrado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
