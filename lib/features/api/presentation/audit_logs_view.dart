import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/fluent_design.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../domain/repository.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({
    this.rows = const [],
    this.repository,
    this.onRefresh,
    super.key,
  });

  final List<Json> rows;
  final Repository? repository;
  final Future<void> Function()? onRefresh;

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  List<Json> _rows = [];
  final Map<String, String> _actorNames = {};
  String _action = 'Todas';
  String _actor = 'Todos';
  String _period = 'Todos';
  int _page = 0;
  int _size = 10;
  bool _loading = false;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows = List<Json>.from(widget.rows);
    if (widget.repository != null) _load();
  }

  @override
  void didUpdateWidget(covariant AuditLogsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows && widget.repository == null) {
      _rows = List<Json>.from(widget.rows);
      _resetFiltersIfNeeded();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = widget.repository;
    if (repository == null || _refreshing) return;
    setState(() {
      _loading = _rows.isEmpty;
      _refreshing = _rows.isNotEmpty;
      _error = null;
    });
    try {
      final loaded = <Json>[];
      for (var offset = 0; offset < 500; offset += 100) {
        final page = await repository.get(
          '/audit?limit=100&offset=$offset&sort=created_at&direction=desc',
        );
        final rows = (page as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        loaded.addAll(rows);
        if (rows.length < 100) break;
      }
      final users = await repository
          .get('/users?limit=100&offset=0')
          .catchError((_) => <dynamic>[]);
      final actorNames = <String, String>{
        for (final raw in users as List)
          if (raw is Map && '${raw['id'] ?? ''}'.isNotEmpty)
            '${raw['id']}': '${raw['name'] ?? raw['id']}',
      };
      if (!mounted) return;
      setState(() {
        _rows = loaded;
        _actorNames
          ..clear()
          ..addAll(actorNames);
        _page = 0;
        _resetFiltersIfNeeded();
      });
      await widget.onRefresh?.call();
    } catch (failure) {
      if (mounted) setState(() => _error = '$failure');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  void _resetFiltersIfNeeded() {
    if (!_rows.any((row) => _actionValue(row) == _action)) _action = 'Todas';
    if (!_rows.any((row) => _actorValue(row) == _actor)) _actor = 'Todos';
    _page = 0;
  }

  String _value(Json row, String key, [String? alternative]) =>
      '${row[key] ?? row[alternative] ?? '—'}';

  String _actionValue(Json row) => _value(row, 'action');
  String _actorValue(Json row) {
    final explicit = '${row['actor_name'] ?? ''}'.trim();
    if (explicit.isNotEmpty) return explicit;
    final actorId = '${row['actor_id'] ?? ''}'.trim();
    return _actorNames[actorId] ?? (actorId.isEmpty ? '—' : actorId);
  }

  DateTime? _date(Json row) =>
      DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal();

  String _detailsText(Json row) {
    final details = row['details'] ?? row['description'];
    if (details == null) return '—';
    if (details is Map || details is List) {
      return const JsonEncoder.withIndent('  ').convert(details);
    }
    return '$details';
  }

  String _entity(String action) {
    final value = action.split('.').first;
    return const {
          'client': 'Cliente',
          'payment': 'Pagamento',
          'cash': 'Caixa',
          'loan': 'Crédito',
          'account': 'Conta',
          'operation': 'Operação',
          'user': 'Utilizador',
          'profile': 'Perfil',
        }[value] ??
        value;
  }

  String _actionLabel(String action) {
    final parts = action.split('.');
    final verb = parts.length > 1 ? parts.last : action;
    return const {
          'create': 'Criado',
          'update': 'Actualizado',
          'withdrawal': 'Levantamento',
          'deposit': 'Depósito',
          'reverse': 'Estornado',
          'cancel': 'Cancelado',
          'corrected': 'Corrigido',
          'disburse': 'Desembolsado',
        }[verb] ??
        action;
  }

  Color _actionColor(String action) {
    final colors = Theme.of(context).colorScheme;
    if (action.contains('cancel') ||
        action.contains('reject') ||
        action.contains('reverse')) {
      return colors.error;
    }
    if (action.contains('update') ||
        action.contains('correct') ||
        action.contains('withdrawal')) {
      return colors.secondary;
    }
    return colors.primary;
  }

  Widget _actionChip(Json row) {
    final action = _actionValue(row);
    final color = _actionColor(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        _actionLabel(action),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  List<String> _cells(Json row) {
    final date = _date(row);
    String pad(int value) => value.toString().padLeft(2, '0');
    final action = _actionValue(row);
    return [
      _entity(action),
      _actionLabel(action),
      date == null ? '—' : '${pad(date.day)}/${pad(date.month)}/${date.year}',
      date == null
          ? '—'
          : '${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}',
      _actorValue(row),
      _value(row, 'entity_id'),
      _detailsText(row),
    ];
  }

  static const _headers = [
    'Entidade',
    'Acção',
    'Data',
    'Hora',
    'Utilizador',
    'ID do registo',
    'Detalhes',
  ];

  bool _inPeriod(Json row) {
    final date = _date(row);
    if (_period == 'Todos' || date == null) return true;
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);
    return switch (_period) {
      'Hoje' => !date.isBefore(startToday),
      '7 dias' => date.isAfter(now.subtract(const Duration(days: 7))),
      '30 dias' => date.isAfter(now.subtract(const Duration(days: 30))),
      _ => true,
    };
  }

  List<Json> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _rows.where((row) {
      return (_action == 'Todas' || _actionValue(row) == _action) &&
          (_actor == 'Todos' || _actorValue(row) == _actor) &&
          _inPeriod(row) &&
          (query.isEmpty ||
              _cells(row).join(' ').toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _export() async {
    final location = await getSaveLocation(
      suggestedName:
          'auditoria_${DateTime.now().toIso8601String().substring(0, 10)}.csv',
    );
    if (location == null) return;
    final output = StringBuffer()..writeln(_headers.map(_csv).join(','));
    for (final row in _filtered) {
      output.writeln(_cells(row).map(_csv).join(','));
    }
    await XFile.fromData(
      utf8.encode(output.toString()),
      mimeType: 'text/csv',
    ).saveTo(location.path);
    if (mounted) {
      await showFeedbackDialog(
        context,
        title: 'Auditoria exportada',
        message: 'O ficheiro foi guardado em ${location.path}.',
        success: true,
      );
    }
  }

  String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  void _details(Json row) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: const Text('Detalhes do evento'),
      subtitle:
          'Auditoria · Registo ${_value(row, 'entity_id')} · ${_cells(row)[2]} às ${_cells(row)[3]}',
      icon: FluentIcons.history,
      content: DetailFields(
        fields: [
          for (final (index, value) in _cells(row).indexed)
            (_headers[index], value),
          ('Código da acção', _actionValue(row)),
          ('ID do evento', _value(row, 'id')),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Concluir'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final actions = _rows.map(_actionValue).toSet().toList()..sort();
    final actors = _rows.map(_actorValue).toSet().toList()..sort();
    final filtered = _filtered;
    final pages = (filtered.length / _size).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final visible = filtered.skip(page * _size).take(_size).toList();
    final today = _rows.where((row) {
      final date = _date(row);
      final now = DateTime.now();
      return date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.history, color: colors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auditoria', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Rastreie actividades, alterações e operações sensíveis do sistema.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _refreshing || _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: filtered.isEmpty ? null : _export,
              icon: const Icon(Icons.download),
              label: const Text('Exportar CSV'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Eventos carregados', '${_rows.length}'),
            _metric('Hoje', '$today'),
            _metric('Utilizadores', '${actors.length}'),
            _metric('Acções distintas', '${actions.length}'),
          ],
        ),
        const SizedBox(height: 18),
        FluentSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar evento, utilizador ou registo',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setState(() => _page = 0),
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<String>(
                      initialValue: _action,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Acção'),
                      items: [
                        const DropdownMenuItem(
                          value: 'Todas',
                          child: Text('Todas'),
                        ),
                        for (final value in actions)
                          DropdownMenuItem(
                            value: value,
                            child: Text(_actionLabel(value)),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _action = value ?? 'Todas';
                        _page = 0;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _actor,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Utilizador',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todos'),
                        ),
                        for (final value in actors)
                          DropdownMenuItem(value: value, child: Text(value)),
                      ],
                      onChanged: (value) => setState(() {
                        _actor = value ?? 'Todos';
                        _page = 0;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<String>(
                      initialValue: _period,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Período'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Todos',
                          child: Text('Todo o período'),
                        ),
                        DropdownMenuItem(value: 'Hoje', child: Text('Hoje')),
                        DropdownMenuItem(
                          value: '7 dias',
                          child: Text('Últimos 7 dias'),
                        ),
                        DropdownMenuItem(
                          value: '30 dias',
                          child: Text('Últimos 30 dias'),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        _period = value ?? 'Todos';
                        _page = 0;
                      }),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _search.clear();
                      _action = 'Todas';
                      _actor = 'Todos';
                      _period = 'Todos';
                      _page = 0;
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
              if (_refreshing) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 18),
              if (_error != null)
                Column(
                  children: [
                    const Text(
                      'Não foi possível carregar os eventos de auditoria.',
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('Nenhum registo encontrado'),
                )
              else
                Scrollbar(
                  controller: _scroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        for (final header in _headers.take(6))
                          DataColumn(label: Text(header.toUpperCase())),
                        const DataColumn(label: Text('ACÇÕES')),
                      ],
                      rows: [
                        for (final row in visible)
                          DataRow(
                            cells: [
                              DataCell(Text(_cells(row)[0])),
                              DataCell(_actionChip(row)),
                              for (final value in _cells(row).skip(2).take(4))
                                DataCell(Text(value)),
                              DataCell(
                                IconButton(
                                  tooltip: 'Ver detalhes do evento',
                                  onPressed: () => _details(row),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: Text(
                      filtered.isEmpty
                          ? 'A mostrar 0 registos'
                          : 'A mostrar ${page * _size + 1}–${page * _size + visible.length} de ${filtered.length} registos',
                    ),
                  ),
                  DropdownButton<int>(
                    value: _size,
                    items: const [10, 25, 50]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value por página'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _size = value ?? 10;
                      _page = 0;
                    }),
                  ),
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: page > 0 ? () => setState(() => _page--) : null,
                    icon: const Icon(Icons.arrowBack),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Página ${pages == 0 ? 0 : page + 1} de $pages',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Página seguinte',
                    onPressed: page + 1 < pages
                        ? () => setState(() => _page++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 5),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );
}
