import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import 'package:file_selector/file_selector.dart';
import '../../../app/theme/fluent_design.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../application/settings_controller.dart';
import '../domain/settings_schema.dart';
import 'institution_branding.dart';

part 'settings_panels.dart';
part 'settings_editors.dart';

class InstitutionSettingsView extends StatefulWidget {
  const InstitutionSettingsView({
    required this.controller,
    this.canAdminister = true,
    super.key,
  });
  final InstitutionSettingsController controller;
  final bool canAdminister;
  @override
  State<InstitutionSettingsView> createState() =>
      InstitutionSettingsViewState();
}

class InstitutionSettingsViewState extends State<InstitutionSettingsView> {
  InstitutionSettingsController get model => widget.controller;
  SettingsData get data => model.draft;
  final _form = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _userSearch = TextEditingController();
  final _horizontal = ScrollController();
  String _role = 'Gestor', _document = 'Contrat', _userStatus = 'Todos';
  bool _showErrors = false, _uploading = false;
  int _userPage = 0;
  String get category => model.category;
  SettingsCategory get current =>
      settingsCategories.firstWhere((c) => c.id == category);

  @override
  void initState() {
    super.initState();
    _document = 'Contrato';
  }

  @override
  void dispose() {
    _search.dispose();
    _userSearch.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _rebuild(VoidCallback change) {
    if (mounted) setState(change);
  }

  void _toast(String text) {
    if (mounted) showFeedbackDialog(context, message: text);
  }

  Future<bool> _confirm(
    String title,
    String body, {
    String action = 'Confirmar',
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => PremiumDialog(
          title: Text(title),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(child: Text(body)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<bool> requestLeave() async {
    if (!model.dirty) return true;
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => PremiumDialog(
        title: const Text('Alterações não guardadas'),
        content: const Text(
          'Guarde as alterações antes de sair ou descarte o rascunho. As definições aplicadas serão preservadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: const Text('Continuar a editar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Guardar e sair'),
          ),
        ],
      ),
    );
    if (decision == 'discard') {
      model.discard();
      return true;
    }
    if (decision == 'save') return _save();
    return false;
  }

  Future<bool> _save() async {
    if (!widget.canAdminister || model.saving) return false;
    setState(() => _showErrors = true);
    final errors = model.validationErrors();
    if (errors.isNotEmpty) {
      final first = settingsCategories.firstWhere(
        (c) => c.sections.any(
          (s) => s.fields.any((f) => errors.containsKey(f.key)),
        ),
      );
      await model.selectCategory(first.id);
      _toast('Reveja os campos assinalados em ${first.title}.');
      return false;
    }
    final critical = model.changedKeys.any(
      (key) =>
          [
            'users',
            'roles',
            'permissions',
            'workflow',
            'sequences',
            'accounts',
            'sessions',
            'integrations',
          ].contains(key) ||
          settingsCategories
              .where((c) => c.critical)
              .any(
                (c) => c.sections.any((s) => s.fields.any((f) => f.key == key)),
              ),
    );
    if (critical &&
        !await _confirm(
          'Aplicar alterações críticas?',
          '${model.changedKeys.length} configurações serão actualizadas no ambiente de demonstração. As alterações serão registadas no histórico com o utilizador responsável.',
          action: 'Confirmar e guardar',
        )) {
      return false;
    }
    final saved = await model.save();
    if (saved) {
      applyInstitutionSettings(model.saved);
      if (mounted) setState(() => _showErrors = false);
      _toast('Definições guardadas neste dispositivo.');
    } else if (model.error != null) {
      _toast(model.error!);
    }
    return saved;
  }

  static const _icons = <String, IconData>{
    'institution': FluentIcons.business_center_logo,
    'identity': FluentIcons.document,
    'users': FluentIcons.people,
    'security': FluentIcons.lock,
    'appearance': FluentIcons.color,
    'credit': FluentIcons.money,
    'workflow': FluentIcons.flow,
    'numbering': FluentIcons.numbered_list,
    'finance': FluentIcons.bank,
    'notifications': FluentIcons.mail,
    'data': FluentIcons.database,
    'regional': FluentIcons.globe,
  };

  bool _matches(SettingsCategory c) {
    final query = _search.text.trim().toLowerCase();
    return query.isEmpty ||
        '${c.title} ${c.description} ${c.sections.expand((s) => [s.title, ...s.fields.map((f) => f.label)]).join(' ')}'
            .toLowerCase()
            .contains(query);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      if (model.loading) return _skeleton();
      final colors = Theme.of(context).colorScheme;
      final matching = settingsCategories.where(_matches).toList();
      return PopScope(
        canPop: !model.dirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && await requestLeave() && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 20,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        FluentIcons.settings,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Definições institucionais',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            'Administração · ${data['tradeName']}',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _badge('Ambiente de demonstração', icon: FluentIcons.info),
              ],
            ),
            const SizedBox(height: 20),
            _surface(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _badge(
                    model.dirty
                        ? '${model.changedKeys.length} alterações não guardadas'
                        : 'Todas as alterações guardadas',
                    icon: model.dirty
                        ? FluentIcons.edit
                        : FluentIcons.check_mark,
                  ),
                  TextButton.icon(
                    onPressed: model.dirty ? _reviewChanges : null,
                    icon: const Icon(FluentIcons.history, size: 16),
                    label: const Text('Rever alterações'),
                  ),
                  OutlinedButton(
                    onPressed: !model.dirty || model.saving
                        ? null
                        : () async {
                            if (await _confirm(
                              'Descartar alterações?',
                              'O rascunho será substituído pela última versão guardada.',
                              action: 'Descartar',
                            )) {
                              model.discard();
                            }
                          },
                    child: const Text('Descartar'),
                  ),
                  FilledButton.icon(
                    onPressed:
                        !model.dirty || model.saving || !widget.canAdminister
                        ? null
                        : _save,
                    icon: model.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(FluentIcons.save, size: 16),
                    label: Text(
                      model.saving ? 'A guardar…' : 'Guardar alterações',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (model.error != null) _notice(model.error!, error: true),
            if (!widget.canAdminister)
              _notice(
                'Consulta disponível. Apenas gestores podem alterar definições institucionais.',
              ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1000;
                final navigation = _surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONFIGURAÇÕES',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.3,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar configurações',
                          prefixIcon: const Icon(FluentIcons.search, size: 16),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar pesquisa',
                                  onPressed: () => setState(_search.clear),
                                  icon: const Icon(FluentIcons.clear, size: 14),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      if (matching.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Nenhuma configuração encontrada.'),
                        ),
                      if (wide)
                        ...matching.map(_categoryTile)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in matching)
                              ChoiceChip(
                                label: Text(c.title),
                                selected: c.id == category,
                                onSelected: (_) => model.selectCategory(c.id),
                              ),
                          ],
                        ),
                      if (wide) ...[
                        const Divider(height: 28),
                        Text(
                          'Preferências de navegação guardadas automaticamente.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                );
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _surface(
                      child: Row(
                        children: [
                          Icon(
                            _icons[category] ?? FluentIcons.settings,
                            color: colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  current.description,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    IgnorePointer(
                      ignoring: !widget.canAdminister || model.saving,
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (category == 'appearance') _appearancePreview(),
                            for (final section in current.sections)
                              _section(section),
                            ..._specialPanels(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 260, child: navigation),
                          const SizedBox(width: 20),
                          Expanded(child: content),
                        ],
                      )
                    : Column(
                        children: [
                          navigation,
                          const SizedBox(height: 16),
                          content,
                        ],
                      );
              },
            ),
          ],
        ),
      );
    },
  );

  Widget _categoryTile(SettingsCategory c) {
    final selected = category == c.id;
    final scheme = Theme.of(context).colorScheme;
    final dirty = c.sections.any(
      (s) => s.fields.any((f) => model.changedKeys.contains(f.key)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(
            _icons[c.id],
            size: 18,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          title: Text(
            c.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurface,
            ),
          ),
          trailing: dirty
              ? Icon(FluentIcons.circle_fill, size: 7, color: scheme.primary)
              : null,
          onTap: () => model.selectCategory(c.id),
        ),
      ),
    );
  }

  Widget _surface({required Widget child}) => FluentSurface(
    padding: const EdgeInsets.all(20),
    child: Material(type: MaterialType.transparency, child: child),
  );
  Widget _badge(String label, {IconData? icon}) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice(String text, {bool error = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            (error
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary)
                .withValues(alpha: .07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(error ? FluentIcons.warning : FluentIcons.info, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    ),
  );

  Widget _section(SettingsSection section) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            section.description,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 500
                  ? 2
                  : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 20,
                children: [
                  for (final field in section.fields)
                    SizedBox(
                      width:
                          (constraints.maxWidth - 16 * (columns - 1)) / columns,
                      child: _field(field),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _field(SettingField field) {
    final key = ValueKey('${field.key}-${model.revision}');
    if (field.initial is bool) {
      return SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label, style: const TextStyle(fontSize: 13)),
        subtitle: field.help == null
            ? null
            : Text(field.help!, style: const TextStyle(fontSize: 11)),
        value: data[field.key] == true,
        onChanged: (v) {
          model.set(field.key, v);
          applyInstitutionSettings(model.draft);
        },
      );
    }
    if (field.options.isNotEmpty) {
      return DropdownButtonFormField<String>(
        key: key,
        initialValue: '${data[field.key]}',
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: field.options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (v) {
          model.set(field.key, v);
          applyInstitutionSettings(model.draft);
        },
      );
    }
    final color = field.key.endsWith('Color');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: key,
          initialValue: '${data[field.key]}',
          keyboardType: field.initial is num
              ? const TextInputType.numberWithOptions(decimal: true)
              : field.key.toLowerCase().contains('email')
              ? TextInputType.emailAddress
              : TextInputType.text,
          minLines:
              [
                'legalText',
                'documentNotes',
                'requiredDocuments',
                'eligibility',
                'creditStates',
              ].contains(field.key)
              ? 2
              : 1,
          maxLines:
              [
                'legalText',
                'documentNotes',
                'requiredDocuments',
                'eligibility',
                'creditStates',
              ].contains(field.key)
              ? 4
              : 1,
          decoration: InputDecoration(
            labelText: '${field.label}${field.required ? ' *' : ''}',
            errorText: _showErrors ? model.validationErrors()[field.key] : null,
            suffixIcon: field.help != null
                ? Tooltip(
                    message: field.help!,
                    child: const Icon(FluentIcons.info, size: 16),
                  )
                : color
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _color('${data[field.key]}'),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )
                : null,
          ),
          validator: (value) => validateSetting(field, value ?? ''),
          onChanged: (v) {
            model.set(
              field.key,
              field.initial is num
                  ? num.tryParse(v.replaceAll(',', '.')) ?? v
                  : v,
            );
            applyInstitutionSettings(model.draft);
          },
        ),
        if (color) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final hex in [
                '#21A56B',
                '#2F6BFF',
                '#6750A4',
                '#00897B',
                '#152739',
                '#C2185B',
                '#F57C00',
                '#0078D4',
              ])
                Tooltip(
                  message: hex,
                  child: InkWell(
                    onTap: () {
                      model.set(field.key, hex);
                      applyInstitutionSettings(model.draft);
                      model.revision++;
                      model.refresh();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: _color(hex),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: '${data[field.key]}' == hex
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color _color(String value) => Color(
    0xff000000 |
        (int.tryParse(value.replaceFirst('#', ''), radix: 16) ?? 0x21a56b),
  );

  Widget _skeleton() => Column(
    children: [
      for (final height in [90.0, 65.0, 220.0, 180.0])
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: LinearProgressIndicator()),
          ),
        ),
    ],
  );

  Future<void> _reviewChanges() => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: const Text('Rever alterações'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final key in model.changedKeys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(key),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        _summaryValue(model.saved[key]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Icon(FluentIcons.chevron_down, size: 12),
                      Text(
                        _summaryValue(data[key]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
  String _summaryValue(dynamic value) => value is List
      ? '${value.length} registos · ${jsonEncode(value).substring(0, jsonEncode(value).length.clamp(0, 180))}'
      : value is Map
      ? 'Configuração estruturada actualizada'
      : '$value';
  String _label(String key) {
    for (final c in settingsCategories) {
      for (final s in c.sections) {
        for (final f in s.fields) {
          if (f.key == key) return f.label;
        }
      }
    }
    return {
          'assets': 'Identidade visual',
          'users': 'Utilizadores',
          'permissions': 'Permissões',
          'roles': 'Perfis',
          'branches': 'Agências',
          'workflow': 'Fluxo de aprovação',
          'templates': 'Templates',
          'sequences': 'Sequências',
          'messages': 'Mensagens',
          'accounts': 'Contas',
          'sessions': 'Sessões',
          'integrations': 'Integrações',
          'signers': 'Signatários',
        }[key] ??
        key;
  }
}
