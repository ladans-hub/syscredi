import 'package:flutter/material.dart' hide Icons;
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import '../../../app/theme/fluent_design.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../domain/repository.dart';
import '../../../core/widgets/premium_dialog.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({required this.rows, super.key});
  final List<Json> rows;

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _table = 'Todas';
  int _page = 0, _size = 10;

  @override
  void didUpdateWidget(covariant AuditLogsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _page = 0;
      if (!widget.rows.any((r) => _value(r, 'table', 'entity') == _table)) {
        _table = 'Todas';
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _value(Json row, String key, [String? alternative]) =>
      '${row[key] ?? row[alternative] ?? '—'}';

  List<String> _cells(Json row) {
    final date = DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return [
      _value(row, 'table', 'entity'),
      _value(row, 'action'),
      date == null ? '—' : '${pad(date.day)}/${pad(date.month)}/${date.year}',
      date == null
          ? '—'
          : '${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}',
      _value(row, 'actor_name', 'actor_id'),
      _value(row, 'entity_id'),
      _value(row, 'description', 'details'),
    ];
  }

  static const _headers = [
    'Tabela',
    'Acção',
    'Data',
    'Hora',
    'Utilizador',
    'ID do registo',
    'Descrição',
  ];

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
    final tables =
        widget.rows.map((r) => _value(r, 'table', 'entity')).toSet().toList()
          ..sort();
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.rows
        .where(
          (r) =>
              (_table == 'Todas' || _value(r, 'table', 'entity') == _table) &&
              _cells(r).join(' ').toLowerCase().contains(query),
        )
        .toList();
    final pages = (filtered.length / _size).ceil();
    final visible = filtered.skip(_page * _size).take(_size).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gestão de logs', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Consulte as actividades e os eventos de auditoria do sistema.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FluentSurface(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Histórico de actividades',
                    style: theme.textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.rows.length} registos carregados',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth < 640
                          ? constraints.maxWidth
                          : 340,
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar nos logs',
                          hintText: 'Utilizador, acção, registo ou descrição',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar pesquisa',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() {
                                    _search.clear();
                                    _page = 0;
                                  }),
                                ),
                        ),
                        onChanged: (_) => setState(() => _page = 0),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 240
                          ? constraints.maxWidth
                          : 220,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_table),
                        initialValue: _table,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Tabela'),
                        items: ['Todas', ...tables]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _table = value ?? 'Todas';
                          _page = 0;
                        }),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _size,
                        decoration: const InputDecoration(
                          labelText: 'Por página',
                        ),
                        items: [5, 10, 25, 50]
                            .map(
                              (n) => DropdownMenuItem(
                                value: n,
                                child: Text('$n registos'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _size = value ?? 10;
                          _page = 0;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (visible.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search,
                          size: 36,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.rows.isEmpty
                              ? 'Sem eventos de auditoria'
                              : 'Nenhum registo encontrado',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.rows.isEmpty
                              ? 'Os eventos registados serão apresentados aqui.'
                              : 'Ajuste a pesquisa ou o filtro de tabela.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) => Scrollbar(
                    controller: _scroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            colors.primary.withValues(alpha: .06),
                          ),
                          headingTextStyle: theme.textTheme.labelLarge
                              ?.copyWith(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                          horizontalMargin: 16,
                          columnSpacing: 24,
                          dataRowMinHeight: 60,
                          dataRowMaxHeight: 76,
                          columns: [
                            ..._headers,
                            'Acções',
                          ].map((h) => DataColumn(label: Text(h))).toList(),
                          rows: visible
                              .map(
                                (row) => DataRow(
                                  cells: [
                                    for (final (index, text) in _cells(
                                      row,
                                    ).indexed)
                                      DataCell(
                                        index == 1
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colors.primary
                                                      .withValues(alpha: .08),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  text,
                                                  style: TextStyle(
                                                    color: colors.primary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              )
                                            : SizedBox(
                                                width: index == 6
                                                    ? 280
                                                    : index == 4
                                                    ? 220
                                                    : null,
                                                child: Text(
                                                  text,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                      ),
                                    DataCell(
                                      IconButton(
                                        tooltip: 'Ver detalhes do evento',
                                        icon: Icon(
                                          FluentIcons.info,
                                          color: colors.primary,
                                          size: 20,
                                        ),
                                        onPressed: () => _details(row),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 12,
                children: [
                  Text(
                    filtered.isEmpty
                        ? '0 registos'
                        : 'A mostrar ${_page * _size + 1}–${_page * _size + visible.length} de ${filtered.length} registos',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Página anterior',
                        onPressed: _page > 0
                            ? () => setState(() => _page--)
                            : null,
                        icon: const Icon(Icons.arrowBack),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Página ${pages == 0 ? 0 : _page + 1} de $pages',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Página seguinte',
                        onPressed: _page + 1 < pages
                            ? () => setState(() => _page++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
