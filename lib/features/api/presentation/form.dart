import 'package:syscredi/core/widgets/equal_button_group.dart';
import 'package:flutter/material.dart';
import '../domain/repository.dart';
import '../domain/money.dart';

class Field {
  const Field(
    this.key,
    this.label, {
    this.initial = '',
    this.optional = false,
    this.kind = 'text',
    this.options,
    this.resource,
  });
  final String key, label, initial, kind;
  final bool optional;
  final Map<String, String>? options;
  final String? resource;
}

Future<Json?> form(
  BuildContext context,
  Repository api,
  String title,
  List<Field> fields,
) => showDialog<Json>(
  context: context,
  builder: (_) => _Form(api: api, title: title, fields: fields),
);

class _Form extends StatefulWidget {
  const _Form({
    required this.api,
    required this.title,
    required this.fields,
  });
  final Repository api;
  final String title;
  final List<Field> fields;
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final form = GlobalKey<FormState>();
  late final controllers = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: f.initial),
  };
  final labels = <String, String>{};
  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    final result = <String, dynamic>{};
    for (final f in widget.fields) {
      final value = controllers[f.key]!.text.trim();
      if (f.optional && value.isEmpty) continue;
      result[f.key] = switch (f.kind) {
        'money' || 'rate' => moneyInput(value),
        'int' => int.parse(value),
        'bool' => value == 'true',
        'date' => DateTime.parse(value).toUtc().toIso8601String(),
        _ => value,
      };
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.fields.map((f) {
              final controller = controllers[f.key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: f.options != null
                    ? DropdownButtonFormField<String>(
                        initialValue: controller.text.isEmpty
                            ? null
                            : controller.text,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: f.label),
                        items: f.options!.entries
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => controller.text = v ?? '',
                        validator: (v) => v == null && !f.optional
                            ? 'Seleccione uma opção.'
                            : null,
                      )
                    : TextFormField(
                        controller: controller,
                        readOnly: f.resource != null,
                        decoration: InputDecoration(
                          labelText: f.label,
                          helperText: labels[f.key],
                          suffixIcon: f.resource != null
                              ? const Icon(Icons.search)
                              : null,
                        ),
                        keyboardType: ['money', 'rate', 'int'].contains(f.kind)
                            ? const TextInputType.numberWithOptions(
                                decimal: true,
                              )
                            : TextInputType.text,
                        onTap: f.resource == null
                            ? null
                            : () async {
                                final picked = await showDialog<Json>(
                                  context: context,
                                  builder: (_) => Picker(
                                    api: widget.api,
                                    resource: f.resource!,
                                    title: f.label,
                                  ),
                                );
                                if (picked != null && mounted) {
                                  setState(() {
                                    controller.text = picked['id'];
                                    labels[f.key] = resourceLabel(picked);
                                  });
                                }
                              },
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) {
                            return f.optional ? null : 'Campo obrigatório.';
                          }
                          try {
                            if (['money', 'rate'].contains(f.kind)) {
                              moneyInput(value);
                            }
                            if (f.kind == 'int' &&
                                (int.tryParse(value) == null ||
                                    int.parse(value) < 1)) {
                              return 'Introduza um inteiro positivo.';
                            }
                            if (f.kind == 'date' &&
                                !RegExp(
                                  r'^\d{4}-\d{2}-\d{2}$',
                                ).hasMatch(value)) {
                              return 'Use AAAA-MM-DD.';
                            }
                            if (f.kind == 'date') {
                              final parsed = DateTime.parse(value);
                              if (parsed.toIso8601String().split('T').first !=
                                  value) {
                                return 'Data inválida.';
                              }
                            }
                          } catch (_) {
                            return 'Valor inválido; use até duas casas decimais.';
                          }
                          return null;
                        },
                      ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
    actions: [
      EqualButtonGroup(
        alignment: WrapAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(onPressed: submit, child: const Text('Continuar')),
        ],
      ),
    ],
  );
}

String resourceLabel(Json row) =>
    row['name']?.toString() ??
    row['reference']?.toString() ??
    row['id']?.toString() ??
    '';

class Picker extends StatefulWidget {
  const Picker({
    required this.api,
    required this.resource,
    required this.title,
    super.key,
  });
  final Repository api;
  final String resource, title;
  @override
  State<Picker> createState() => _PickerState();
}

class _PickerState extends State<Picker> {
  List<Json> rows = [];
  bool loading = true;
  int offset = 0;
  String sort = 'created_at';
  String direction = 'desc';
  String? error;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final path = widget.resource == 'payment-accounts'
          ? '/payment-accounts'
          : '/${widget.resource}?limit=50&offset=$offset&q=${Uri.encodeQueryComponent(search.text.trim())}&sort=$sort&direction=$direction';
      final values = (await widget.api.get(path) as List)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
      if (mounted) setState(() => rows = values);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 500,
      height: 400,
      child: Column(
        children: [
          if (widget.resource != 'payment-accounts')
            TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: 'Pesquisar',
                suffixIcon: IconButton(
                  onPressed: () {
                    offset = 0;
                    load();
                  },
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) {
                offset = 0;
                load();
              },
            ),
          if (widget.resource != 'payment-accounts')
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: sort,
                    decoration: const InputDecoration(labelText: 'Ordenar por'),
                    items: const [
                      DropdownMenuItem(
                        value: 'created_at',
                        child: Text('Data'),
                      ),
                      DropdownMenuItem(value: 'name', child: Text('Nome')),
                      DropdownMenuItem(value: 'status', child: Text('Estado')),
                      DropdownMenuItem(
                        value: 'amount_cents',
                        child: Text('Montante'),
                      ),
                      DropdownMenuItem(
                        value: 'balance_cents',
                        child: Text('Saldo'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        sort = value;
                        offset = 0;
                      });
                      load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: direction == 'desc'
                      ? 'Mais recentes primeiro'
                      : 'Mais antigos primeiro',
                  onPressed: () {
                    setState(() {
                      direction = direction == 'desc' ? 'asc' : 'desc';
                      offset = 0;
                    });
                    load();
                  },
                  icon: Icon(direction == 'desc' ? Icons.south : Icons.north),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final row in rows)
                  ListTile(
                    title: Text(resourceLabel(row)),
                    subtitle: Text(
                      row['document']?.toString() ?? row['id'].toString(),
                    ),
                    onTap: loading ? null : () => Navigator.pop(context, row),
                  ),
                if (!loading && rows.isEmpty)
                  const ListTile(title: Text('Nenhum registo encontrado.')),
              ],
            ),
          ),
          if (widget.resource != 'payment-accounts')
            EqualButtonGroup(
              alignment: WrapAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: offset > 0 && !loading
                      ? () {
                          offset -= 50;
                          load();
                        }
                      : null,
                  child: const Text('Anterior'),
                ),
                TextButton(
                  onPressed: rows.length == 50 && !loading
                      ? () {
                          offset += 50;
                          load();
                        }
                      : null,
                  child: const Text('Seguinte'),
                ),
              ],
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
    ],
  );
}
