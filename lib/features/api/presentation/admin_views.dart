import 'dart:convert';

import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../domain/money.dart';
import '../domain/repository.dart';
import 'form.dart';

class AdminView extends StatefulWidget {
  const AdminView({
    required this.kind,
    required this.repository,
    this.canManage = false,
    super.key,
  });

  final String kind;
  final Repository repository;
  final bool canManage;

  @override
  State<AdminView> createState() => _AdminViewState();
}

class _AdminViewState extends State<AdminView> {
  final searchController = TextEditingController();
  List<Json> rows = [];
  bool loading = true;
  bool refreshing = false;
  bool writing = false;
  String query = '';
  String filter = 'Todos';
  String? error;

  _AdminSpec get spec => _specs[widget.kind] ?? _specs['accounting']!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      rows = [];
      filter = 'Todos';
      query = '';
      searchController.clear();
      _load();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (refreshing) return;
    setState(() {
      loading = rows.isEmpty;
      refreshing = rows.isNotEmpty;
      error = null;
    });
    try {
      final value = await widget.repository.get(
        '/${spec.resource}?limit=100&offset=0',
      );
      if (!mounted) return;
      setState(() {
        rows = (value as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .where((row) => widget.kind != 'users' || row['active'] == true)
            .toList();
      });
    } catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
    }
  }

  String _status(Json row) => switch (widget.kind) {
    'accounting' => 'Confirmado',
    'sync' => '${row['status'] ?? 'accepted'}',
    'aml' => '${row['status'] ?? 'open'}',
    'users' => row['active'] == true ? 'active' : 'inactive',
    'backup' => '${row['status'] ?? 'available'}',
    _ => '—',
  };

  List<String> get statuses => rows.map(_status).toSet().toList()..sort();

  String _searchText(Json row) {
    final values = <Object?>[
      ...row.values,
      if (widget.kind == 'users') ...[
        _role('${row['role'] ?? ''}'),
        _statusLabel(_status(row)),
      ],
    ];
    return _normalizeSearch(values.join(' '));
  }

  String _normalizeSearch(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòôõö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c');

  List<Json> get shown {
    final normalized = _normalizeSearch(query.trim());
    return rows.where((row) {
      return (filter == 'Todos' || _status(row) == filter) &&
          (normalized.isEmpty || _searchText(row).contains(normalized));
    }).toList();
  }

  int _sumLines(Json row, String key) {
    final lines = row['lines'];
    if (lines is! List) return 0;
    return lines.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item is Map ? (num.tryParse('${item[key] ?? 0}') ?? 0).round() : 0),
    );
  }

  String _cell(Json row, String key) => switch (key) {
    'date' => _date(row['created_at'] ?? row['updated_at']),
    'source' => '${row['source'] ?? '—'}',
    'reference' =>
      '${row['reference'] ?? row['client_operation_id'] ?? row['storage_key'] ?? row['id'] ?? '—'}',
    'description' =>
      '${row['reason'] ?? row['operation'] ?? row['name'] ?? row['error'] ?? '—'}',
    'status' => _statusLabel(_status(row)),
    'role' => _role('${row['role'] ?? ''}'),
    'debit' => money(_sumLines(row, 'debit')),
    'credit' => money(_sumLines(row, 'credit')),
    'severity' => _severity('${row['severity'] ?? ''}'),
    'size' => _bytes(row['size_bytes']),
    'encrypted' => row['encrypted'] == true ? 'Sim' : 'Não',
    'active' => row['active'] == true ? 'Activo' : 'Inactivo',
    'hash' => '${row['payload_hash'] ?? row['checksum'] ?? '—'}',
    'user' => '${row['name'] ?? row['user_id'] ?? '—'}',
    _ => '${row[key] ?? '—'}',
  };

  String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _bytes(dynamic value) {
    final bytes = (num.tryParse('${value ?? 0}') ?? 0).toDouble();
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    }
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${bytes.round()} B';
  }

  String _role(String value) =>
      const {
        'manager': 'Gestor',
        'analyst': 'Analista',
        'operator': 'Operador',
        'guarantor': 'Fiador',
      }[value] ??
      value;

  String _severity(String value) =>
      const {'low': 'Baixa', 'medium': 'Média', 'high': 'Alta'}[value] ?? value;

  String _statusLabel(String value) =>
      const {
        'accepted': 'Aceite',
        'applied': 'Aplicada',
        'rejected': 'Rejeitada',
        'open': 'Aberto',
        'investigating': 'Em investigação',
        'resolved': 'Resolvido',
        'dismissed': 'Arquivado',
        'active': 'Activo',
        'inactive': 'Inactivo',
        'available': 'Disponível',
        'restoring': 'A restaurar',
        'revoked': 'Revogado',
      }[value] ??
      value;

  Widget _sourceChip(Json row) {
    final source = '${row['source'] ?? '—'}';
    final color = source.contains('withdrawal')
        ? const Color(0xff9a6200)
        : source.contains('payment')
        ? Theme.of(context).colorScheme.primary
        : Colors.teal;
    final label =
        const {
          'payment': 'Pagamento',
          'disbursement': 'Desembolso',
          'manual.withdrawal': 'Despesa manual',
          'manual.deposit': 'Receita manual',
          'transfer.in': 'Transferência recebida',
          'transfer.out': 'Transferência enviada',
          'opening': 'Abertura de conta',
        }[source] ??
        source;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _syncChip(Json row, String key) {
    final value = _cell(row, key);
    final colors = Theme.of(context).colorScheme;
    final color = key == 'description' ? colors.primary : colors.secondary;
    final label = key == 'reference' && value.length > 20
        ? '${value.substring(0, 8)}…${value.substring(value.length - 6)}'
        : value;
    return Tooltip(
      message: value,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _tableCell(Json row, String key) {
    if (widget.kind == 'accounting' && key == 'source') {
      return _sourceChip(row);
    }
    if (widget.kind == 'sync' && (key == 'description' || key == 'reference')) {
      return _syncChip(row, key);
    }
    return Text(_cell(row, key));
  }

  Future<void> _create() async {
    switch (widget.kind) {
      case 'aml':
        final body = await form(
          context,
          widget.repository,
          'Novo alerta AML',
          const [
            Field('clientId', 'Cliente', resource: 'clients'),
            Field('reference', 'Referência'),
            Field('reason', 'Motivo'),
            Field(
              'severity',
              'Severidade',
              options: {'low': 'Baixa', 'medium': 'Média', 'high': 'Alta'},
              initial: 'medium',
            ),
          ],
        );
        if (body != null) {
          await _write('POST', '/aml-alerts', body, 'Alerta AML criado');
        }
      case 'users':
        final body = await form(
          context,
          widget.repository,
          'Convidar utilizador',
          const [
            Field('name', 'Nome'),
            Field('email', 'Email'),
            Field(
              'role',
              'Perfil',
              options: {
                'operator': 'Operador',
                'analyst': 'Analista',
                'guarantor': 'Fiador',
              },
              initial: 'operator',
            ),
          ],
        );
        if (body != null) {
          await _write(
            'POST',
            '/organizations/members/invite',
            body,
            'Convite enviado',
          );
        }
      case 'sync':
        final body = await form(
          context,
          widget.repository,
          'Nova operação de sincronização',
          const [
            Field('clientOperationId', 'Identificador da operação'),
            Field('operation', 'Operação'),
            Field('payloadHash', 'Hash do payload'),
            Field(
              'status',
              'Estado',
              options: {
                'accepted': 'Aceite',
                'applied': 'Aplicada',
                'rejected': 'Rejeitada',
              },
              initial: 'accepted',
            ),
          ],
        );
        if (body != null) {
          await _write('POST', '/sync-operations', body, 'Operação registada');
        }
      case 'backup':
        final body = await form(
          context,
          widget.repository,
          'Registar cópia de segurança',
          const [
            Field('storageKey', 'Localização do arquivo'),
            Field('checksum', 'Checksum'),
            Field('sizeBytes', 'Tamanho em bytes', kind: 'nonNegativeInt'),
            Field(
              'encrypted',
              'Cifrado',
              kind: 'bool',
              options: {'true': 'Sim', 'false': 'Não'},
              initial: 'true',
            ),
          ],
        );
        if (body != null) {
          await _write('POST', '/backup-archives', body, 'Backup registado');
        }
      default:
        await showFeedbackDialog(
          context,
          title: 'Contabilidade',
          message:
              'Os lançamentos contabilísticos são gerados automaticamente pelas operações financeiras.',
        );
    }
  }

  Future<void> _rowAction(Json row) async {
    switch (widget.kind) {
      case 'aml':
        final body = await form(
          context,
          widget.repository,
          'Actualizar alerta AML',
          [
            Field(
              'status',
              'Estado',
              options: const {
                'open': 'Aberto',
                'investigating': 'Em investigação',
                'resolved': 'Resolvido',
                'dismissed': 'Arquivado',
              },
              initial: '${row['status'] ?? 'open'}',
            ),
          ],
        );
        if (body != null) {
          await _write(
            'PATCH',
            '/aml-alerts/${row['id']}',
            body,
            'Alerta actualizado',
          );
        }
      case 'users':
        final body = await form(
          context,
          widget.repository,
          'Editar utilizador',
          [
            Field('name', 'Nome', initial: '${row['name'] ?? ''}'),
            Field(
              'role',
              'Perfil',
              options: const {
                'operator': 'Operador',
                'analyst': 'Analista',
                'guarantor': 'Fiador',
                'manager': 'Gestor',
              },
              initial: '${row['role'] ?? 'operator'}',
            ),
            Field(
              'active',
              'Estado',
              kind: 'bool',
              options: const {'true': 'Activo', 'false': 'Inactivo'},
              initial: '${row['active'] ?? true}',
            ),
          ],
        );
        if (body != null) {
          await _write('PUT', '/users', {
            ...body,
            'userId': row['id'],
          }, 'Utilizador actualizado');
        }
      case 'sync':
        final body = await form(
          context,
          widget.repository,
          'Actualizar sincronização',
          [
            Field(
              'status',
              'Estado',
              options: const {
                'accepted': 'Aceite',
                'applied': 'Aplicada',
                'rejected': 'Rejeitada',
              },
              initial: '${row['status'] ?? 'accepted'}',
            ),
            Field(
              'error',
              'Erro',
              optional: true,
              initial: '${row['error'] ?? ''}',
            ),
          ],
        );
        if (body != null) {
          await _write(
            'PATCH',
            '/sync-operations/${row['id']}',
            body,
            'Sincronização actualizada',
          );
        }
      case 'backup':
        await _write(
          'POST',
          '/backup-archives/${row['id']}/restore',
          const {},
          'Restauração iniciada',
        );
      default:
        _details(row);
    }
  }

  Future<void> _removeUser(Json row) async {
    if ('${row['role']}' == 'manager') return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumDialog(
        title: const Text('Remover utilizador?'),
        content: Text(
          'O acesso de ${row['name'] ?? 'este utilizador'} será removido da organização. Esta acção não está disponível para gestores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover utilizador'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _write(
      'DELETE',
      '/users/${Uri.encodeComponent('${row['id']}')}',
      const {},
      'Utilizador removido',
    );
  }

  Future<void> _write(
    String method,
    String path,
    Json body,
    String title,
  ) async {
    if (writing) return;
    setState(() => writing = true);
    try {
      await widget.repository.write(method, path, body);
      await _load();
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: title,
          message: 'A operação foi confirmada e a lista foi actualizada.',
          success: true,
        );
      }
    } catch (failure) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Operação não concluída',
          message: '$failure',
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  void _details(Json row) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: Text('Detalhes · ${spec.title}'),
      subtitle: '${row['id'] ?? row['reference'] ?? 'Registo administrativo'}',
      icon: spec.icon,
      content: DetailFields(
        fields: [
          for (final entry in row.entries)
            if (entry.key != 'organization_id')
              (
                entry.key,
                entry.value is Map || entry.value is List
                    ? const JsonEncoder.withIndent('  ').convert(entry.value)
                    : '${entry.value ?? '—'}',
              ),
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
    final filtered = shown;
    final pendingCount = rows.where((row) {
      final status = _status(row);
      return [
        'accepted',
        'open',
        'investigating',
        'restoring',
      ].contains(status);
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(spec.icon, size: 30, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.title, style: theme.textTheme.headlineSmall),
                  Text(spec.subtitle),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: refreshing || loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
            if (widget.canManage || widget.kind != 'users') ...[
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: writing ? null : _create,
                icon: const Icon(Icons.add),
                label: Text(spec.action),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Registos', '${rows.length}'),
            _metric('Pendentes', '$pendingCount'),
            _metric('Estados', '${statuses.length}'),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: widget.kind == 'users'
                      ? 'Pesquisar utilizadores'
                      : 'Pesquisar em ${spec.title.toLowerCase()}',
                  hintText: widget.kind == 'users'
                      ? 'Nome, email, perfil ou estado'
                      : null,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          onPressed: () {
                            searchController.clear();
                            setState(() => query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                initialValue: filter,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  for (final status in statuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                ],
                onChanged: (value) => setState(() => filter = value ?? 'Todos'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() {
                searchController.clear();
                query = '';
                filter = 'Todos';
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Limpar'),
            ),
          ],
        ),
        if (refreshing || writing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 14),
        if (error != null)
          Column(
            children: [
              Text('Não foi possível carregar ${spec.title.toLowerCase()}.'),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nenhum registo encontrado em ${spec.title.toLowerCase()}.',
              ),
            ),
          )
        else
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  for (final column in spec.columns)
                    DataColumn(label: Text(column.$1.toUpperCase())),
                  const DataColumn(label: Text('ACÇÕES')),
                ],
                rows: [
                  for (final row in filtered)
                    DataRow(
                      cells: [
                        for (final column in spec.columns)
                          DataCell(_tableCell(row, column.$2)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Ver detalhes',
                                onPressed: () => _details(row),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              if (widget.kind != 'accounting')
                                IconButton(
                                  tooltip: spec.rowAction,
                                  onPressed: writing
                                      ? null
                                      : () => _rowAction(row),
                                  icon: Icon(spec.rowActionIcon),
                                ),
                              if (widget.kind == 'users' &&
                                  '${row['role']}' != 'manager')
                                IconButton(
                                  tooltip: 'Remover utilizador',
                                  onPressed: writing
                                      ? null
                                      : () => _removeUser(row),
                                  icon: Icon(
                                    Icons.delete_sweep_outlined,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _metric(String label, String value) => SizedBox(
    width: 220,
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

class _AdminSpec {
  const _AdminSpec({
    required this.title,
    required this.subtitle,
    required this.resource,
    required this.icon,
    required this.action,
    required this.columns,
    required this.rowAction,
    required this.rowActionIcon,
  });

  final String title;
  final String subtitle;
  final String resource;
  final IconData icon;
  final String action;
  final List<(String, String)> columns;
  final String rowAction;
  final IconData rowActionIcon;
}

const _specs = <String, _AdminSpec>{
  'accounting': _AdminSpec(
    title: 'Contabilidade',
    subtitle:
        'Lançamentos contabilísticos gerados pelas operações financeiras.',
    resource: 'journal',
    icon: Icons.menu_book_outlined,
    action: 'Informação',
    columns: [
      ('Data', 'date'),
      ('Origem', 'source'),
      ('Referência', 'source_id'),
      ('Débitos', 'debit'),
      ('Créditos', 'credit'),
    ],
    rowAction: 'Ver lançamento',
    rowActionIcon: Icons.visibility_outlined,
  ),
  'sync': _AdminSpec(
    title: 'Sincronização',
    subtitle:
        'Operações offline, estados de aplicação e conflitos de sincronização.',
    resource: 'sync-operations',
    icon: Icons.sync,
    action: 'Nova operação',
    columns: [
      ('Data', 'date'),
      ('Operação', 'description'),
      ('Identificador', 'reference'),
      ('Estado', 'status'),
      ('Hash', 'hash'),
    ],
    rowAction: 'Actualizar estado',
    rowActionIcon: Icons.edit,
  ),
  'aml': _AdminSpec(
    title: 'Alertas AML',
    subtitle:
        'Monitorização e resolução de alertas de prevenção de branqueamento.',
    resource: 'aml-alerts',
    icon: Icons.shield,
    action: 'Novo alerta',
    columns: [
      ('Data', 'date'),
      ('Referência', 'reference'),
      ('Motivo', 'description'),
      ('Severidade', 'severity'),
      ('Estado', 'status'),
    ],
    rowAction: 'Actualizar alerta',
    rowActionIcon: Icons.edit,
  ),
  'users': _AdminSpec(
    title: 'Utilizadores',
    subtitle: 'Perfis, funções e estado de acesso à organização.',
    resource: 'users',
    icon: Icons.people,
    action: 'Convidar utilizador',
    columns: [
      ('Utilizador', 'user'),
      ('Perfil', 'role'),
      ('Estado', 'active'),
      ('Criado em', 'date'),
    ],
    rowAction: 'Editar utilizador',
    rowActionIcon: Icons.edit,
  ),
  'backup': _AdminSpec(
    title: 'Cópias de segurança',
    subtitle: 'Arquivos cifrados, integridade e operações de restauração.',
    resource: 'backup-archives',
    icon: Icons.download,
    action: 'Registar backup',
    columns: [
      ('Data', 'date'),
      ('Arquivo', 'reference'),
      ('Tamanho', 'size'),
      ('Cifrado', 'encrypted'),
      ('Estado', 'status'),
    ],
    rowAction: 'Restaurar backup',
    rowActionIcon: Icons.refresh,
  ),
};
