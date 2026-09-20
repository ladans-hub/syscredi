import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/settings_schema.dart';

SettingsData copySettings(SettingsData value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

/// Local demonstration store. No authentication, financial or server policy is
/// changed here. Audit entries are append-only through this interface; a local
/// mock store cannot offer the tamper resistance of a server audit service.
class InstitutionSettingsController extends ChangeNotifier {
  InstitutionSettingsController({required this.scope, required this.actor});
  final String scope, actor;
  SettingsData saved = defaultSettings();
  SettingsData draft = defaultSettings();
  List<SettingsData> _audit = [];
  List<SettingsData> get audit => List.unmodifiable(
    _audit.map((e) => Map<String, dynamic>.unmodifiable(copySettings(e))),
  );
  bool loading = true, saving = false;
  String? error;
  String category = 'institution';
  int revision = 0;
  bool _disposed = false;
  String get _key => 'institution.demo.v1.$scope';
  bool get dirty => jsonEncode(saved) != jsonEncode(draft);
  List<String> get changedKeys => draft.keys
      .where((k) => jsonEncode(saved[k]) != jsonEncode(draft[k]))
      .toList();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final envelope = jsonDecode(raw) as Map;
        saved = validateImport(envelope);
        _audit = (envelope['audit'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      draft = copySettings(saved);
      final last = prefs.getString('$_key.category');
      if (saved['rememberCategory'] == true &&
          settingsCategories.any((c) => c.id == last)) {
        category = last!;
      }
    } catch (_) {
      error =
          'Não foi possível ler as definições locais. Tente novamente; os dados guardados não foram substituídos.';
    } finally {
      loading = false;
      _emit();
    }
  }

  void set(String key, dynamic value) {
    if (key == 'signer' || key == 'signerRole') {
      final column = key == 'signer' ? 'name' : 'position';
      for (final row in draft['signers'] as List) {
        if (row[column] == draft[key]) row[column] = value;
      }
    }
    draft[key] = value;
    _emit();
  }

  void refresh() => _emit();
  void discard() {
    draft = copySettings(saved);
    revision++;
    _emit();
  }

  void restoreAppearance() {
    final defaults = defaultSettings();
    for (final section
        in settingsCategories
            .firstWhere((c) => c.id == 'appearance')
            .sections) {
      for (final field in section.fields) {
        draft[field.key] = defaults[field.key];
      }
    }
    revision++;
    _emit();
  }

  Future<void> selectCategory(String next) async {
    category = next;
    _emit();
    if (saved['rememberCategory'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_key.category', next);
      } catch (_) {
        /* Optional UI preference; financial settings are unaffected. */
      }
    }
  }

  Map<String, String> validationErrors() {
    final errors = <String, String>{};
    for (final category in settingsCategories) {
      for (final section in category.sections) {
        for (final field in section.fields) {
          final error = validateSetting(field, '${draft[field.key] ?? ''}');
          if (error != null) errors[field.key] = error;
        }
      }
    }
    final min = num.tryParse('${draft['minimumCredit']}') ?? 0;
    final max = num.tryParse('${draft['maximumCredit']}') ?? 0;
    if (max < min) {
      errors['maximumCredit'] = 'O máximo deve ser superior ao mínimo.';
    }
    return errors;
  }

  Future<bool> save({String reason = 'Actualização de definições'}) async {
    if (saving || !dirty) return false;
    if (validationErrors().isNotEmpty) {
      error = 'Existem campos inválidos. Reveja os campos assinalados.';
      _emit();
      return false;
    }
    try {
      validateImport({'version': 1, 'settings': draft});
    } on FormatException catch (failure) {
      error = failure.message;
      _emit();
      return false;
    }
    saving = true;
    error = null;
    _emit();
    final next = copySettings(draft);
    final changes = changedKeys
        .map(
          (k) => <String, dynamic>{
            'field': k,
            'before': k == 'assets' ? 'Identidade anterior' : saved[k],
            'after': k == 'assets' ? 'Identidade actualizada' : next[k],
          },
        )
        .toList();
    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'actor': actor,
      'action': reason,
      'module': 'Definições institucionais',
      'at': DateTime.now().toIso8601String(),
      'changes': changes,
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(
        _key,
        jsonEncode({
          'version': 1,
          'settings': next,
          'audit': [..._audit, entry],
        }),
      );
      if (!success) throw StateError('Storage write failed');
      saved = next;
      draft = copySettings(next);
      _audit = [..._audit, entry];
      revision++;
      return true;
    } catch (_) {
      error =
          'Não foi possível guardar. As alterações continuam disponíveis para tentar novamente.';
      return false;
    } finally {
      saving = false;
      _emit();
    }
  }

  Future<void> recordOperation(String action) async {
    final entry = <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'actor': actor,
      'action': action,
      'module': 'Dados e integrações',
      'at': DateTime.now().toIso8601String(),
      'changes': <dynamic>[],
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(
        _key,
        jsonEncode({
          'version': 1,
          'settings': saved,
          'audit': [..._audit, entry],
        }),
      );
      if (!success) throw StateError('Storage write failed');
      _audit = [..._audit, entry];
    } catch (_) {
      error =
          'A operação foi concluída, mas não foi possível guardar o histórico local.';
    }
    _emit();
  }

  String exportJson() => const JsonEncoder.withIndent(
    '  ',
  ).convert({'version': 1, 'mode': 'demonstration', 'settings': saved});

  void importJson(String raw) {
    if (raw.length > 16000000) {
      throw const FormatException('O ficheiro excede o limite de 16 MB.');
    }
    draft = validateImport(jsonDecode(raw));
    revision++;
    _emit();
  }

  static SettingsData validateImport(dynamic decoded) {
    if (decoded is! Map ||
        decoded['version'] != 1 ||
        decoded['settings'] is! Map) {
      throw const FormatException(
        'Formato de configurações inválido (versão 1).',
      );
    }
    final incoming = Map<String, dynamic>.from(decoded['settings'] as Map);
    final defaults = defaultSettings();
    if (incoming.keys.any((k) => !defaults.containsKey(k))) {
      throw const FormatException('O ficheiro contém campos desconhecidos.');
    }
    final value = {...defaults, ...incoming};
    for (final c in settingsCategories) {
      for (final s in c.sections) {
        for (final f in s.fields) {
          final v = value[f.key];
          if ((f.initial is bool && v is! bool) ||
              (f.options.isNotEmpty && !f.options.contains(v)) ||
              validateSetting(f, '$v') != null) {
            throw FormatException('Campo inválido: ${f.label}.');
          }
        }
      }
    }
    for (final key in [
      'branches',
      'users',
      'workflow',
      'sequences',
      'signers',
      'templates',
      'accounts',
      'messages',
      'sessions',
      'integrations',
    ]) {
      final rows = value[key];
      final sample = (defaults[key] as List).first as Map;
      if (rows is! List ||
          rows.length > 1000 ||
          rows.any(
            (r) => r is! Map || sample.keys.any((k) => r[k] is! String),
          )) {
        throw FormatException('Lista inválida: $key.');
      }
    }
    if (value['roles'] is! List ||
        (value['roles'] as List).any((r) => r is! String) ||
        !(value['roles'] as List).contains('Gestor')) {
      throw const FormatException('Perfis inválidos.');
    }
    if (value['permissions'] is! Map) {
      throw const FormatException('Permissões inválidas.');
    }
    for (final role in value['roles'] as List) {
      final permissions = value['permissions'][role];
      if (permissions is! Map ||
          permissionModules.any(
            (m) =>
                permissions[m] is! List ||
                (permissions[m] as List).any(
                  (a) => !permissionActions.contains(a),
                ),
          )) {
        throw const FormatException('Matriz de permissões inválida.');
      }
    }
    if (permissionModules.any(
      (m) => permissionActions.any(
        (a) => !(value['permissions']['Gestor'][m] as List).contains(a),
      ),
    )) {
      throw const FormatException(
        'O perfil Gestor deve conservar as permissões administrativas.',
      );
    }
    if ((value['branches'] as List).isEmpty ||
        (value['branches'] as List).map((b) => b['code']).toSet().length !=
            (value['branches'] as List).length) {
      throw const FormatException('É necessária uma agência com código único.');
    }
    for (final key in ['signers', 'templates']) {
      if (documentTypes.any(
        (type) =>
            (value[key] as List).where((r) => r['document'] == type).length !=
            1,
      )) {
        throw const FormatException(
          'Os tipos de documento obrigatórios devem ser preservados.',
        );
      }
    }
    final users = value['users'] as List;
    if (!users.any((u) => u['role'] == 'Gestor' && u['status'] == 'Activo')) {
      throw const FormatException('É necessário manter um Gestor activo.');
    }
    final emails = users.map((u) => '${u['email']}'.toLowerCase()).toSet();
    if (emails.length != users.length ||
        users.any(
          (u) =>
              !(value['roles'] as List).contains(u['role']) ||
              !(value['branches'] as List).any((b) => b['code'] == u['branch']),
        )) {
      throw const FormatException(
        'Utilizadores duplicados ou com perfil/agência inválidos.',
      );
    }
    if (value['assets'] is! Map ||
        (value['assets'] as Map).values.any(
          (a) =>
              a is! Map ||
              a['name'] is! String ||
              a['data'] is! String ||
              !RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(a['data'] as String),
        )) {
      throw const FormatException('Identidade visual inválida.');
    }
    if ((num.tryParse('${value['maximumCredit']}') ?? 0) <
        (num.tryParse('${value['minimumCredit']}') ?? 0)) {
      throw const FormatException('Limites de crédito inválidos.');
    }
    for (final asset in (value['assets'] as Map).values) {
      try {
        final bytes = base64Decode(asset['data'] as String);
        if (bytes.length < 24 ||
            bytes.length > 8000000 ||
            bytes[0] != 137 ||
            bytes[1] != 80 ||
            bytes[2] != 78 ||
            bytes[3] != 71) {
          throw const FormatException('Imagem PNG inválida no ficheiro.');
        }
      } catch (_) {
        throw const FormatException('Imagem inválida no ficheiro.');
      }
    }
    return copySettings(value);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
