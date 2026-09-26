import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syscredi/features/api/domain/repository.dart';
import 'package:syscredi/features/settings/application/settings_controller.dart';
import 'package:syscredi/features/settings/domain/settings_schema.dart';
import 'package:syscredi/features/settings/presentation/institution_settings_view.dart';
import 'package:syscredi/features/settings/presentation/institution_branding.dart';
import 'package:syscredi/app/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('email sender uses institution name with Syscredi fallback', () {
    expect(institutionEmailSenderName({}), 'Syscredi');
    expect(
      institutionEmailSenderName({
        'tradeName': '  Cooperativa Horizonte  ',
        'legalName': 'Horizonte, SA',
      }),
      'Cooperativa Horizonte',
    );
    expect(
      institutionEmailSenderName({
        'tradeName': ' ',
        'legalName': 'Horizonte, SA',
      }),
      'Horizonte, SA',
    );
  });

  test(
    'Defaults valid, save persists, discard restores and audit is append-only',
    () async {
      final model = InstitutionSettingsController(
        scope: 'test',
        actor: 'Helena',
      );
      await model.load();
      expect(model.validationErrors(), isEmpty);
      model.set('tradeName', 'Acácia Nova');
      expect(model.dirty, isTrue);
      expect(await model.save(), isTrue);
      expect(model.audit.single['actor'], 'Helena');
      expect(() => model.audit.clear(), throwsUnsupportedError);
      final restored = InstitutionSettingsController(
        scope: 'test',
        actor: 'Helena',
      );
      await restored.load();
      expect(restored.saved['tradeName'], 'Acácia Nova');
      restored.set('nuit', 'invalid');
      expect(await restored.save(), isFalse);
      restored.discard();
      expect(restored.dirty, isFalse);
      expect(restored.audit.length, 1);
      model.dispose();
      restored.dispose();
    },
  );

  test(
    'Import rejects unsupported policies and preserves audit on restore',
    () async {
      final model = InstitutionSettingsController(
        scope: 'test',
        actor: 'Helena',
      );
      await model.load();
      final envelope = {'version': 1, 'settings': defaultSettings()};
      expect(
        InstitutionSettingsController.validateImport(envelope)['nuit'],
        '400123456',
      );
      (envelope['settings'] as Map)['nuit'] = '12';
      expect(
        () => model.importJson(jsonEncode(envelope)),
        throwsFormatException,
      );
      expect(model.dirty, isFalse);
      final data = defaultSettings();
      (data['users'] as List).first['status'] = 'Inactivo';
      expect(
        () => InstitutionSettingsController.validateImport({
          'version': 1,
          'settings': data,
        }),
        throwsFormatException,
      );
      model.dispose();
    },
  );

  test(
    'Shared A4 generator creates documents from configured identity',
    () async {
      final pdf = await InstitutionDocument(
        settings: defaultSettings(),
      ).preview('Contrato');
      expect(ascii.decode(pdf.take(4).toList()), '%PDF');
      expect(pdf.length, greaterThan(1000));
    },
  );

  test('shared document titles occupy full width and stay centered', () {
    final title = InstitutionDocument(
      settings: defaultSettings(),
    ).title('Carta institucional', subtitle: 'Comunicação formal');

    expect(title, isA<pw.Container>());
    final container = title as pw.Container;
    expect(container.constraints?.maxWidth, double.infinity);
    expect(container.alignment, pw.Alignment.center);
  });

  test(
    'Institution identity is reflected immediately in shared in-memory branding',
    () {
      final data = defaultSettings();
      data['tradeName'] = 'Cooperativa Horizonte';
      data['institutionBio'] = 'Crédito simples para negócios locais.';
      applyInstitutionSettings(data);
      expect(brandVisuals.value.institutionName, 'Cooperativa Horizonte');
      expect(
        brandVisuals.value.institutionBio,
        'Crédito simples para negócios locais.',
      );
      expect(institutionBranding.value['tradeName'], 'Cooperativa Horizonte');
    },
  );

  Future<InstitutionSettingsController> open(
    WidgetTester tester, {
    double width = 1440,
    bool general = false,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final model = InstitutionSettingsController(
      scope: 'widget',
      actor: 'Helena',
    );
    await model.load();
    await model.selectCategory(general ? 'security' : 'institution');
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: InstitutionSettingsView(
                controller: model,
                general: general,
              ),
            ),
          ),
        ),
      ),
    );
    return model;
  }

  testWidgets('Every settings category renders without layout errors', (
    tester,
  ) async {
    const generalIds = {
      'security',
      'appearance',
      'notifications',
      'data',
      'regional',
    };
    var model = await open(tester);
    for (final category in settingsCategories.where(
      (category) => category.id != 'users' && !generalIds.contains(category.id),
    )) {
      await model.selectCategory(category.id);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: category.id);
      expect(find.text(category.description), findsWidgets);
    }
    await tester.pumpWidget(const SizedBox());
    model.dispose();

    model = await open(tester, general: true);
    for (final category in settingsCategories.where(
      (category) => generalIds.contains(category.id),
    )) {
      await model.selectCategory(category.id);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: category.id);
      expect(find.text(category.description), findsWidgets);
    }
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('Narrow settings layout and polished user details', (
    tester,
  ) async {
    final model = await open(tester, width: 390);
    for (final category in settingsCategories.where(
      (category) => !{
        'security',
        'appearance',
        'notifications',
        'data',
        'regional',
      }.contains(category.id),
    )) {
      await model.selectCategory(category.id);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: category.id);
    }
    await model.selectCategory('users');
    await tester.pumpAndSettle();
    // Horizontal tables are intentionally scrollable on narrow screens.
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('Editor validates NUIT and navigation keeps unsaved changes', (
    tester,
  ) async {
    final model = await open(tester);
    model.set('nuit', '12');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar alterações'));
    await tester.pumpAndSettle();
    expect(find.text('O NUIT deve conter 9 dígitos.'), findsOneWidget);
    expect(model.dirty, isTrue);
    await model.selectCategory('users');
    await tester.pumpAndSettle();
    expect(model.draft['nuit'], '12');
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  test('remote settings load and save through production API routes', () async {
    final repository = _SettingsRepository();
    final model = InstitutionSettingsController(
      scope: 'remote',
      actor: 'Gestor',
      repository: repository,
    );
    await model.load();
    expect(model.saved['tradeName'], 'Instituição Remota');
    expect(model.saved['theme'], 'Escuro');

    model.set('tradeName', 'Instituição Actualizada');
    expect(await model.save(), isTrue);
    expect(repository.writes, hasLength(1));
    expect(repository.writes.single.method, 'POST');
    expect(repository.writes.single.path, '/organization-settings/batch');
    expect(
      repository.writes.single.body['settings'],
      contains(
        allOf(
          containsPair('key', 'tradeName'),
          containsPair('value', 'Instituição Actualizada'),
        ),
      ),
    );
    model.dispose();
  });

  test('save ignores legacy keys already present in memory', () async {
    final repository = _SettingsRepository();
    final model = InstitutionSettingsController(
      scope: 'legacy-save',
      actor: 'tester',
      repository: repository,
    );
    await model.load();
    model.draft['legacyBackendField'] = 'old-value';
    model.set('tradeName', 'Instituição Actualizada');

    expect(await model.save(), isTrue);
    expect(model.saved.containsKey('legacyBackendField'), isFalse);
    final settings = repository.writes.single.body['settings'] as List;
    expect(
      settings.any((entry) => entry['key'] == 'legacyBackendField'),
      isFalse,
    );
  });

  test('settings requests stay below the API body limit', () async {
    final repository = _SettingsRepository();
    final model = InstitutionSettingsController(
      scope: 'batched-save',
      actor: 'tester',
      repository: repository,
    );
    await model.load();
    model.set('legalText', List.filled(50000, 'A').join());
    model.set('documentNotes', List.filled(50000, 'B').join());

    expect(await model.save(), isTrue);
    expect(repository.writes, isNotEmpty);
    for (final write in repository.writes) {
      expect(
        utf8.encode(jsonEncode(write.body)).length,
        lessThan(4 * 1024 * 1024),
      );
    }
  });
}

class _SettingsRepository implements Repository {
  final writes = <({String method, String path, Json body})>[];

  @override
  Future<dynamic> get(String path) async => {
    'data': [
      {'key': 'tradeName', 'value': 'Instituição Remota'},
      {'key': 'theme', 'value': 'Escuro'},
    ],
  };

  @override
  Future<dynamic> write(String method, String path, Json body) async {
    writes.add((method: method, path: path, body: body));
    return {'updated': (body['settings'] as List).length};
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
