import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/auth/presentation/login_page.dart';

Widget _app({
  Future<void> Function(String, String)? login,
  Future<void> Function(String)? recoverPassword,
}) => MaterialApp(
  home: LoginPage(
    onAuthenticated: (_) {},
    login: login,
    recoverPassword: recoverPassword,
  ),
);

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email profissional'),
    'gestor@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Palavra-passe'),
    'password123',
  );
}

void main() {
  testWidgets('erro de login abre alerta e não aparece sob o botão', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        login: (_, _) async =>
            throw const ApiFailure('Credenciais inválidas.', status: 401),
      ),
    );
    await _enterCredentials(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Não foi possível entrar'), findsOneWidget);
    expect(find.text('Credenciais inválidas.'), findsOneWidget);
    expect(find.textContaining('ApiFailure:'), findsNothing);
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets('recuperação concluída abre alerta informativo', (tester) async {
    await tester.pumpWidget(_app(recoverPassword: (_) async {}));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email profissional'),
      'gestor@example.com',
    );

    await tester.tap(find.text('Esqueci a palavra-passe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Verifique o seu email'), findsOneWidget);
    expect(
      find.text('Enviámos as instruções de recuperação para o seu email.'),
      findsOneWidget,
    );
    expect(find.text('Fechar'), findsOneWidget);
  });

  testWidgets('email inválido na recuperação abre alerta informativo', (
    tester,
  ) async {
    await tester.pumpWidget(_app(recoverPassword: (_) async {}));

    await tester.tap(find.text('Esqueci a palavra-passe'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Informação'), findsOneWidget);
    expect(find.text('Indique primeiro um email válido.'), findsOneWidget);
    expect(find.text('Fechar'), findsOneWidget);
  });
}
