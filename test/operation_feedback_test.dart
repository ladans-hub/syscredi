import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/core/widgets/operation_feedback.dart';

void main() {
  Future<void> openDialog(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showFeedbackDialog(
                  context,
                  title: 'Não foi possível guardar',
                  message:
                      'O campo accountId possui um identificador inválido. Seleccione o registo novamente e tente outra vez.',
                  success: false,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('alerta cabe num dispositivo pequeno', (tester) async {
    await openDialog(tester, const Size(320, 568));

    expect(tester.takeException(), isNull);
    expect(find.text('Não foi possível guardar'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('feedback-dialog-panel'))).width,
      lessThanOrEqualTo(292),
    );
  });

  testWidgets('alerta mantém largura premium no desktop', (tester) async {
    await openDialog(tester, const Size(1200, 800));

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('feedback-dialog-panel'))).width,
      lessThanOrEqualTo(400),
    );
  });
}
