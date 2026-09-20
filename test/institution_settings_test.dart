import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syscredi/features/settings/application/settings_controller.dart';
import 'package:syscredi/features/settings/domain/settings_schema.dart';
import 'package:syscredi/features/settings/presentation/institution_settings_view.dart';
import 'package:syscredi/features/settings/presentation/institution_branding.dart';
import 'package:syscredi/app/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: InstitutionSettingsView(controller: model),
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
    final model = await open(tester);
    for (final category in settingsCategories) {
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
    for (final category in settingsCategories) {
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
}
