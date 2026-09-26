import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/report_views.dart';
import 'package:syscredi/features/settings/domain/settings_schema.dart';
import 'package:syscredi/features/settings/presentation/institution_branding.dart';

class ReportRepository implements Repository {
  int reads = 0;

  @override
  Future<dynamic> get(String path) async {
    reads++;
    if (path.startsWith('/clients')) {
      return [
        {'id': 'c1', 'name': 'Ana Manuel', 'phone': '841234567'},
      ];
    }
    if (path.startsWith('/loans')) {
      return [
        {
          'id': 'l1',
          'reference': 'CRE-001',
          'client_id': 'c1',
          'principal_cents': 100000,
          'status': 'active',
        },
      ];
    }
    return <Json>[];
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
  testWidgets('relatório carrega uma vez e mantém dados ao reconstruir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = ReportRepository();
    Widget app() => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReportView(kind: 'Créditos', repository: repository),
        ),
      ),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('CRE-001'), findsOneWidget);
    expect(repository.reads, 6);

    await tester.pumpWidget(app());
    await tester.pump();
    expect(repository.reads, 6);
  });

  testWidgets('carta BM permite escolher periodicidade', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportView(
              kind: 'Carta para BM',
              repository: ReportRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Carta e reporte para o Banco de Moçambique'),
      findsOneWidget,
    );
    expect(find.text('Periodicidade'), findsOneWidget);
    expect(find.text('Mensal'), findsWidgets);
  });

  testWidgets('pesquisa filtra os resultados apresentados', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportView(kind: 'Créditos', repository: ReportRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.widgetWithText(TextField, 'Pesquisar nos resultados');
    await tester.enterText(search, 'ana manuel');
    await tester.pump();
    expect(find.text('CRE-001'), findsOneWidget);

    await tester.enterText(search, 'inexistente');
    await tester.pump();
    expect(find.text('CRE-001'), findsNothing);
    expect(find.text('Sem registos para apresentar.'), findsOneWidget);
  });

  testWidgets('bloqueia geração sem assinatura e carimbo', (tester) async {
    final previous = institutionBranding.value;
    addTearDown(() => institutionBranding.value = previous);
    final settings = defaultSettings();
    settings['assets'] = <String, dynamic>{};
    institutionBranding.value = settings;
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportView(kind: 'Créditos', repository: ReportRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'PDF'));
    await tester.pumpAndSettle();
    expect(find.text('Assinatura e carimbo obrigatórios'), findsOneWidget);
  });

  testWidgets('mostra exportação PDF individual por registo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportView(kind: 'Créditos', repository: ReportRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Gerar CSV deste registo'), findsOneWidget);
    expect(find.byTooltip('Gerar PDF deste registo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'PDF'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'CSV'), findsOneWidget);
  });

  testWidgets('cartas permitem apenas exportação PDF', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportView(kind: 'Cartas', repository: ReportRepository()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'PDF'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'CSV'), findsNothing);
    expect(find.byTooltip('Gerar PDF deste registo'), findsOneWidget);
    expect(find.byTooltip('Gerar CSV deste registo'), findsNothing);
  });
}
