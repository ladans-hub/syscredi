import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/api/presentation/credit_products.dart';

class ProductRepository implements Repository {
  ProductRepository({
    this.products = const <Json>[],
    this.enforceProductVersions = false,
  });

  final List<Json> products;
  final bool enforceProductVersions;
  final writes = <({String method, String path, Json body})>[];
  int productVersion = 1;

  @override
  Future<dynamic> get(String path) async => products;

  @override
  Future<dynamic> write(String method, String path, Json body) async {
    if (enforceProductVersions && path.startsWith('/products/')) {
      if (body['version'] != productVersion) {
        throw const ApiFailure('Versão desactualizada.', status: 409);
      }
      productVersion++;
    }
    writes.add((method: method, path: path, body: body));
    return {'id': 'product-1', 'version': productVersion};
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

void main() {
  testWidgets('pesquisa produtos por nome, código, tipo e descrição', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = ProductRepository(
      products: [
        {
          'id': 'product-1',
          'name': 'Crédito Pessoal',
          'code': 'PESSOAL-01',
          'description': 'Financiamento para despesas familiares',
          'product_type': 'individual',
          'status': 'active',
          'version': 1,
        },
        {
          'id': 'product-2',
          'name': 'Capital de Giro',
          'code': 'EMP-02',
          'description': 'Apoio para pequenas empresas',
          'product_type': 'business',
          'status': 'active',
        },
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreditProductsView(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.widgetWithText(
      TextField,
      'Pesquisar produto, código ou tipo',
    );
    await tester.enterText(search, 'credito');
    await tester.pump();
    expect(find.text('Crédito Pessoal'), findsOneWidget);
    expect(find.text('Capital de Giro'), findsNothing);

    await tester.enterText(search, 'emp-02');
    await tester.pump();
    expect(find.text('Crédito Pessoal'), findsNothing);
    expect(find.text('Capital de Giro'), findsOneWidget);

    await tester.enterText(search, 'pequenas empresas');
    await tester.pump();
    expect(find.text('Capital de Giro'), findsOneWidget);
    expect(find.text('Crédito Pessoal'), findsNothing);
  });

  testWidgets('novo produto abre e envia payload válido para API', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = ProductRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreditProductsView(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo produto'));
    await tester.pumpAndSettle();
    expect(find.text('Novo produto de crédito'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do produto'),
      'Crédito Pessoal',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código único'),
      'PESSOAL-01',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição comercial'),
      'Produto para necessidades pessoais.',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montante mínimo'),
      '1000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Montante máximo'),
      '50000',
    );
    final save = find.text('Guardar produto');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(repository.writes.single.path, '/products');
    expect(
      repository.writes.single.body,
      containsPair('name', 'Crédito Pessoal'),
    );
    expect(repository.writes.single.body, containsPair('code', 'PESSOAL-01'));
    expect(
      repository.writes.single.body,
      containsPair('minAmountCents', 100000),
    );
    expect(
      repository.writes.single.body,
      containsPair('maxAmountCents', 5000000),
    );
    expect(find.text('Produto guardado'), findsOneWidget);
    expect(
      find.text('O produto de crédito foi confirmado pelo servidor.'),
      findsOneWidget,
    );
  });

  testWidgets('alterna produto entre desactivado e activado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = ProductRepository(
      enforceProductVersions: true,
      products: [
        {
          'id': 'product-1',
          'name': 'Crédito Pessoal',
          'code': 'PESSOAL-01',
          'product_type': 'individual',
          'status': 'active',
          'version': 1,
        },
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CreditProductsView(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    final deactivateButton = find.byTooltip('Desactivar produto');
    await tester.ensureVisible(deactivateButton);
    await tester.pumpAndSettle();
    await tester.tap(deactivateButton);
    await tester.pumpAndSettle();
    expect(find.text('Desactivar produto de crédito?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'PATCH');
    expect(repository.writes.single.path, '/products/product-1');
    expect(repository.writes.single.body, containsPair('status', 'inactive'));
    expect(repository.writes.single.body, containsPair('active', false));
    expect(find.text('Crédito Pessoal'), findsOneWidget);
    expect(find.text('Inactivo'), findsOneWidget);
    expect(find.text('Produto desactivado'), findsOneWidget);

    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    final activateButton = find.byTooltip('Activar produto');
    await tester.ensureVisible(activateButton);
    await tester.tap(activateButton);
    await tester.pumpAndSettle();
    expect(find.text('Activar produto de crédito?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Activar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.writes, hasLength(2));
    expect(repository.writes.last.body, containsPair('version', 2));
    expect(repository.writes.last.body, containsPair('status', 'active'));
    expect(repository.writes.last.body, containsPair('active', true));
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Produto activado'), findsOneWidget);
  });
}
