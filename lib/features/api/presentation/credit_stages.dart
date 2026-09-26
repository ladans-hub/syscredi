import 'dart:async';

import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../domain/money.dart';
import '../domain/repository.dart';

/// Operações de crédito agrupadas por etapa do ciclo de vida.
///
class CreditStagesView extends StatefulWidget {
  const CreditStagesView({
    required this.stage,
    required this.repository,
    this.role = 'manager',
    super.key,
  });
  final String stage;
  final Repository repository;
  final String role;

  @override
  State<CreditStagesView> createState() => _CreditStagesViewState();
}

class _CreditStagesViewState extends State<CreditStagesView> {
  final List<String> _clients = [];
  final List<String> _processes = [];
  final List<String> _authorizers = [];
  final Map<String, String> _accounts = {};
  final Map<String, String> _clientIds = {};
  final List<Map<String, dynamic>> _products = [];
  final List<_CreditCase> _cases = [];
  final TextEditingController _searchController = TextEditingController();
  String filter = 'Todos';
  String query = '';
  _CreditCase? selected;
  bool loading = true;
  bool refreshing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CreditStagesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    query = '';
    filter = 'Todos';
  }

  Future<void> _load() async {
    final initialLoad = _cases.isEmpty;
    final selectedId = selected?.id;
    setState(() {
      loading = initialLoad;
      refreshing = !initialLoad;
      error = null;
      if (initialLoad) selected = null;
    });
    try {
      final loans =
          widget.stage == 'credit-status' ||
          widget.stage == 'credit-restructuring';
      final results = await Future.wait<dynamic>([
        widget.repository.get(
          loans ? '/loans?limit=100&offset=0' : '/requests?limit=100&offset=0',
        ),
        widget.repository.get('/clients?limit=100&offset=0'),
        widget.repository.get(
          loans ? '/loans?limit=100&offset=0' : '/requests?limit=100&offset=0',
        ),
        widget.repository.get('/users?limit=100&offset=0'),
        widget.repository.get('/payment-accounts'),
        widget.repository.get('/products?limit=100&offset=0'),
      ]);
      final data = results[0];
      if (!mounted) return;
      setState(() {
        final loadedCases = (data as List)
            .map(
              (row) => _CreditCase.fromJson(
                Map<String, dynamic>.from(row as Map),
                loan: loans,
              ),
            )
            .where((item) => _isEligibleForStage(widget.stage, item.rawStage));
        _cases
          ..clear()
          ..addAll(loadedCases);
        if (selectedId != null) {
          selected = _cases.cast<_CreditCase?>().firstWhere(
            (item) => item?.id == selectedId,
            orElse: () => null,
          );
        }
        _clients
          ..clear()
          ..addAll(
            (results[1] as List)
                .where((row) => _clientIdentifier(row as Map).isNotEmpty)
                .map((row) => '${(row as Map)['name'] ?? ''}'.trim())
                .where((name) => name.isNotEmpty),
          );
        _clientIds
          ..clear()
          ..addEntries(
            (results[1] as List)
                .map((row) {
                  final value = row as Map;
                  return MapEntry(
                    '${value['name'] ?? ''}'.trim(),
                    _clientIdentifier(value),
                  );
                })
                .where(
                  (entry) => entry.key.isNotEmpty && entry.value.isNotEmpty,
                ),
          );
        _processes
          ..clear()
          ..addAll(
            _cases.map(
              (item) => item.client.isEmpty
                  ? item.reference
                  : '${item.reference} · ${item.client}',
            ),
          );
        _authorizers
          ..clear()
          ..addAll(
            (results[3] as List)
                .map((row) {
                  final value = row as Map;
                  final name = '${value['name'] ?? ''}'.trim();
                  final role = '${value['role'] ?? ''}'.trim();
                  return role.isEmpty ? name : '$name · $role';
                })
                .where((value) => value.isNotEmpty),
          );
        _accounts
          ..clear()
          ..addEntries(
            _rows(results[4])
                .map((row) {
                  final value = row as Map;
                  final id = _recordIdentifier(value);
                  final name = '${value['name'] ?? ''}'.trim();
                  final currency = '${value['currency'] ?? ''}'.trim();
                  return MapEntry(
                    id,
                    currency.isEmpty ? name : '$name · $currency',
                  );
                })
                .where((entry) => entry.key.isNotEmpty),
          );
        _products
          ..clear()
          ..addAll(
            (results[5] as List)
                .map((row) => Map<String, dynamic>.from(row as Map))
                .where((row) => row['active'] != false),
          );
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

  _StageMeta get meta => _stageMeta[widget.stage] ?? _stageMeta['financing']!;

  static bool _isEligibleForStage(String viewStage, String processStage) =>
      switch (viewStage) {
        'financing' => processStage == 'documentation',
        'financial-analysis' => [
          'documentation',
          'analysis',
        ].contains(processStage),
        'credit-approval' => processStage == 'committee',
        'credit-authorization' => processStage == 'approved',
        'credit-disbursement' => processStage == 'approved',
        'credit-status' => ![
          'paid',
          'cancelled',
          'archived',
        ].contains(processStage),
        'credit-restructuring' => ['active', 'overdue'].contains(processStage),
        _ => true,
      };

  List<_CreditCase> get _disbursementEligibleCases => _cases
      .where((item) => item.rawStage == 'approved')
      .toList(growable: false);

  List<String> get _stageProcesses {
    final cases = widget.stage == 'credit-disbursement'
        ? _disbursementEligibleCases
        : _cases;
    return cases
        .map(
          (item) => item.client.isEmpty
              ? item.reference
              : '${item.reference} · ${item.client}',
        )
        .toList(growable: false);
  }

  List<_CreditCase> get visible => _cases.where((item) {
    final matchesFilter = filter == 'Todos' || item.status == filter;
    final needle = query.trim().toLowerCase();
    final matchesQuery =
        needle.isEmpty ||
        item.client.toLowerCase().contains(needle) ||
        item.reference.toLowerCase().contains(needle);
    return matchesFilter && matchesQuery;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, scheme),
            if (error != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
            const SizedBox(height: 18),
            _kpis(context, scheme),
            const SizedBox(height: 18),
            if (selected != null && !compact) ...[
              _detailPanel(context, scheme, selected!),
              const SizedBox(height: 18),
            ],
            widget.stage == 'credit-status'
                ? _creditStatusWorkspace(context, scheme)
                : _workspace(context, scheme),
            if (selected != null && compact) ...[
              const SizedBox(height: 18),
              _detailPanel(context, scheme, selected!),
            ],
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: meta.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(meta.icon, color: meta.color, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meta.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(meta.subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(meta.action),
      ),
    ],
  );

  Widget _kpis(BuildContext context, ColorScheme scheme) {
    final total = _cases.length;
    final attention = _cases.where((item) => item.attention).length;
    final amount = _cases.fold<double>(0, (sum, item) => sum + item.amount);
    final completion = total == 0
        ? 0.0
        : _cases.where((item) => item.status == 'Concluído').length / total;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _metric(
          context,
          'Processos activos',
          '$total',
          FluentSystemIcons.sync,
          scheme.primary,
        ),
        _metric(
          context,
          'Requer atenção',
          '$attention',
          FluentSystemIcons.warning,
          Colors.orange,
        ),
        _metric(
          context,
          'Montante em fluxo',
          money((amount * 100).round()),
          FluentSystemIcons.wallet,
          scheme.secondary,
        ),
        _metric(
          context,
          'Conclusão',
          '${(completion * 100).round()}%',
          FluentSystemIcons.check,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => SizedBox(
    width: 218,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _workspace(BuildContext context, ColorScheme scheme) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar cliente ou referência',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: filter,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    for (final value in ['Todos', ...meta.statuses])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) =>
                      setState(() => filter = value ?? 'Todos'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(_clearFilters),
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar filtros'),
              ),
              const SizedBox(width: 24),
              Text(
                '${visible.length} registos',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (refreshing) const LinearProgressIndicator(),
          if (loading && _cases.isEmpty)
            const SizedBox(
              height: 220,
              child: CenteredLoadingState(
                message: 'A carregar processos de crédito…',
              ),
            )
          else if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('Nenhum processo corresponde aos filtros.'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 28,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 80,
                headingRowHeight: 48,
                columns: const [
                  DataColumn(label: Text('PROCESSO')),
                  DataColumn(label: Text('CLIENTE')),
                  DataColumn(label: Text('MONTANTE')),
                  DataColumn(label: Text('PRAZO')),
                  DataColumn(label: Text('RESPONSÁVEL')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACÇÕES')),
                ],
                rows: [for (final item in visible) _row(context, scheme, item)],
              ),
            ),
        ],
      ),
    ),
  );

  Widget _creditStatusWorkspace(BuildContext context, ColorScheme scheme) {
    final statuses = [
      'Todos',
      'Liquidados',
      'Vigentes',
      'Em risco',
      'Cancelados',
      'Reprovados',
      'Malparado',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: statuses.contains(filter) ? filter : 'Todos',
                    decoration: const InputDecoration(
                      labelText: 'Estado do crédito',
                    ),
                    items: [
                      for (final value in statuses)
                        DropdownMenuItem(value: value, child: Text(value)),
                    ],
                    onChanged: (value) =>
                        setState(() => filter = value ?? 'Todos'),
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar cliente ou contrato',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => query = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(_clearFilters),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Limpar'),
                ),
                FilledButton.icon(
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Gerar relatório'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('CLIENTE')),
                  DataColumn(label: Text('CAPITAL')),
                  DataColumn(label: Text('PAGAS / PENDENTES')),
                  DataColumn(label: Text('LINHA')),
                  DataColumn(label: Text('DATA')),
                  DataColumn(label: Text('ESTADO')),
                  DataColumn(label: Text('ACÇÕES')),
                ],
                rows: [
                  for (final item in visible)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item.client,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        DataCell(Text(money((item.amount * 100).round()))),
                        DataCell(
                          Text(item.status == 'Concluído' ? '1 / 1' : '0 / 1'),
                        ),
                        DataCell(const Text('Mensal · 30%')),
                        DataCell(Text(item.updated)),
                        DataCell(_statusBadge(item.status)),
                        DataCell(
                          IconButton(
                            tooltip: 'Abrir estado do crédito',
                            onPressed: () => setState(() => selected = item),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String value) {
    final color = value == 'Concluído' || value == 'Liquidado'
        ? Colors.teal
        : value.toLowerCase().contains('risco') ||
              value.toLowerCase().contains('mal')
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  DataRow _row(BuildContext context, ColorScheme scheme, _CreditCase item) =>
      DataRow(
        selected: selected?.reference == item.reference,
        onSelectChanged: (_) => setState(() => selected = item),
        cells: [
          DataCell(
            Text(
              item.reference,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          DataCell(Text(item.client)),
          DataCell(Text(money((item.amount * 100).round()))),
          DataCell(Text('${item.term} meses')),
          DataCell(Text(item.owner)),
          DataCell(_status(item.status, item.attention, scheme)),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Ver detalhe',
                  onPressed: () => setState(() => selected = item),
                  icon: const Icon(Icons.visibility_outlined),
                ),
                IconButton(
                  tooltip: 'Editar processo',
                  onPressed: () => _openEditor(context, item),
                  icon: const Icon(Icons.edit),
                ),
                if (_processActions(item).isNotEmpty)
                  PopupMenuButton<String>(
                    onSelected: (value) => _applyAction(item, value),
                    itemBuilder: (_) => _processActions(item),
                  ),
              ],
            ),
          ),
        ],
      );

  Widget _status(String value, bool attention, ColorScheme scheme) {
    final color = attention
        ? Colors.orange
        : value == 'Concluído'
        ? Colors.teal
        : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPanel(
    BuildContext context,
    ColorScheme scheme,
    _CreditCase item,
  ) => Card(
    color: scheme.primary.withValues(alpha: .035),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Detalhe do processo ${item.reference}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => selected = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 16,
            children: [
              _detail('Cliente', item.client),
              _detail('Produto', item.product),
              _detail('Montante', money((item.amount * 100).round())),
              _detail('Prazo', '${item.term} meses'),
              _detail('Responsável', item.owner),
              _detail('Última actualização', item.updated),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Linha do processo',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 0,
            runSpacing: 8,
            children: [
              for (final (index, label) in [
                'Pedido',
                'Análise',
                'Aprovação',
                'Autorização',
                'Desembolso',
              ].indexed)
                _timelineStep(
                  label,
                  index <= item.progress,
                  index == item.progress,
                  scheme,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (_canAdvance(item))
                  FilledButton.icon(
                    onPressed: () => _applyAction(item, 'advance'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Avançar processo'),
                  ),
                if (widget.stage == 'credit-status') ...[
                  OutlinedButton.icon(
                    onPressed: () => _applyAction(item, 'malparado'),
                    icon: const Icon(Icons.warning_amber_rounded),
                    label: const Text('Tornar malparado'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _applyAction(item, 'revert'),
                    icon: const Icon(Icons.undo_outlined),
                    label: const Text('Reverter crédito'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detail(String label, String value) => SizedBox(
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _timelineStep(
    String label,
    bool complete,
    bool current,
    ColorScheme scheme,
  ) => SizedBox(
    width: 145,
    child: Row(
      children: [
        Icon(
          complete ? Icons.check_circle_outline : Icons.circle,
          size: 18,
          color: current
              ? scheme.primary
              : complete
              ? Colors.teal
              : scheme.outline,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: current ? FontWeight.w800 : FontWeight.w500,
              color: current ? scheme.primary : null,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openEditor(BuildContext context, [_CreditCase? item]) async {
    if (widget.stage != 'financing') {
      await _openStageForm(context, item);
      return;
    }
    if (loading || refreshing) {
      await showFeedbackDialog(
        context,
        title: 'Dados a carregar',
        message:
            'Os clientes e produtos de crédito ainda estão a ser carregados. Aguarde alguns instantes e tente novamente.',
        kind: FeedbackKind.info,
      );
      return;
    }
    if (_clients.isEmpty || _products.isEmpty) {
      await showFeedbackDialog(
        context,
        title: 'Dados indisponíveis',
        message:
            'É necessário cadastrar um cliente e um produto de crédito activo.',
        success: false,
      );
      return;
    }
    final clientOptions = _clientIds.entries
        .map((entry) => (id: entry.value, name: entry.key))
        .where((entry) => _isUuid(entry.id))
        .toList();
    if (clientOptions.isEmpty) {
      await showFeedbackDialog(
        context,
        title: 'Clientes indisponíveis',
        message:
            'Não foi possível obter os identificadores dos clientes. Actualize a tela e tente novamente.',
        success: false,
      );
      return;
    }
    final initialClient = item == null
        ? clientOptions.first
        : clientOptions.firstWhere(
            (entry) => entry.name == item.client,
            orElse: () => clientOptions.first,
          );
    var selectedClient = initialClient.name;
    var selectedClientId = initialClient.id;
    final defaultProduct = _products.firstWhere((product) {
      final name = '${product['name'] ?? ''}'.trim().toLowerCase();
      final code = '${product['code'] ?? ''}'.trim().toLowerCase();
      return name == 'crédito rápido' ||
          name == 'credito rapido' ||
          code.contains('rapido') ||
          code.contains('rápido');
    }, orElse: () => _products.first);
    var selectedProductId = item == null
        ? '${defaultProduct['id'] ?? ''}'
        : '${_products.firstWhere((row) => '${row['name'] ?? ''}' == item.product, orElse: () => _products.first)['id'] ?? ''}';
    Map<String, dynamic> selectedProduct() => _products.firstWhere(
      (product) => '${product['id'] ?? ''}' == selectedProductId,
      orElse: () => defaultProduct,
    );
    int productMonths(String key, {required int fallback}) =>
        int.tryParse('${selectedProduct()[key] ?? fallback}') ?? fallback;
    final amount = TextEditingController(
      text: item?.amount.toStringAsFixed(2) ?? '12500',
    );
    final term = TextEditingController(
      text:
          item?.term.toString() ??
          productMonths('min_months', fallback: 1).toString(),
    );
    final notes = TextEditingController(text: item?.notes ?? '');
    var shortTerm = false;
    bool isQuickCredit() {
      final product = selectedProduct();
      final name = '${product['name'] ?? ''}'.toLowerCase();
      final code = '${product['code'] ?? ''}'.toLowerCase();
      return name.contains('crédito rápido') ||
          name.contains('credito rapido') ||
          code.contains('rapido') ||
          code.contains('rápido');
    }

    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          item == null ? meta.action : 'Editar ${meta.title.toLowerCase()}',
        ),
        content: StatefulBuilder(
          builder: (dialogContext, dialogSetState) => SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FormField<String>(
                      initialValue: selectedClientId,
                      validator: (_) =>
                          !clientOptions.any(
                            (entry) => entry.id == selectedClientId,
                          )
                          ? 'Seleccione um cliente válido.'
                          : null,
                      builder: (field) => InkWell(
                        onTap: () async {
                          var query = '';
                          final value = await showDialog<String>(
                            context: dialogContext,
                            builder: (pickerContext) => StatefulBuilder(
                              builder: (pickerContext, pickerSetState) {
                                final matches = clientOptions
                                    .where(
                                      (client) => client.name
                                          .toLowerCase()
                                          .contains(query.trim().toLowerCase()),
                                    )
                                    .toList();
                                return AlertDialog(
                                  title: const Text('Selecionar cliente'),
                                  content: SizedBox(
                                    width: 460,
                                    height: 360,
                                    child: Column(
                                      children: [
                                        TextField(
                                          autofocus: true,
                                          decoration: const InputDecoration(
                                            labelText: 'Pesquisar cliente',
                                            prefixIcon: Icon(Icons.search),
                                          ),
                                          onChanged: (value) => pickerSetState(
                                            () => query = value,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: matches.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                    'Nenhum cliente encontrado.',
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount: matches.length,
                                                  separatorBuilder: (_, _) =>
                                                      const Divider(height: 1),
                                                  itemBuilder: (_, index) =>
                                                      ListTile(
                                                        leading: const Icon(
                                                          Icons.person_outline,
                                                        ),
                                                        title: Text(
                                                          matches[index].name,
                                                        ),
                                                        selected:
                                                            matches[index].id ==
                                                            selectedClientId,
                                                        onTap: () =>
                                                            Navigator.pop(
                                                              pickerContext,
                                                              matches[index].id,
                                                            ),
                                                      ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                          if (value != null) {
                            final picked = clientOptions.firstWhere(
                              (entry) => entry.id == value,
                            );
                            selectedClient = picked.name;
                            selectedClientId = picked.id;
                            field.didChange(value);
                            dialogSetState(() {});
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Cliente',
                            prefixIcon: const Icon(Icons.people_outline),
                            errorText: field.errorText,
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(selectedClient)),
                              const Icon(Icons.search, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProductId.isEmpty
                          ? null
                          : selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Produto de crédito',
                        prefixIcon: Icon(Icons.apps),
                      ),
                      items: [
                        for (final product in _products)
                          DropdownMenuItem(
                            value: '${product['id'] ?? ''}',
                            child: Text(
                              '${product['name'] ?? 'Produto'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: item == null
                          ? (value) {
                              selectedProductId = value ?? '';
                              term.text = productMonths(
                                'min_months',
                                fallback: 1,
                              ).toString();
                              shortTerm = false;
                              dialogSetState(() {});
                            }
                          : null,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Seleccione o produto de crédito.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    if (item == null && isQuickCredit()) ...[
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Meses'),
                            icon: Icon(FluentSystemIcons.calendar),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Até 14 dias'),
                            icon: Icon(FluentSystemIcons.pending),
                          ),
                        ],
                        selected: {shortTerm},
                        onSelectionChanged: (value) {
                          shortTerm = value.first;
                          term.text = shortTerm
                              ? '14'
                              : productMonths(
                                  'min_months',
                                  fallback: 1,
                                ).toString();
                          dialogSetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: amount,
                            decoration: const InputDecoration(
                              labelText: 'Montante (MT)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => double.tryParse(v ?? '') == null
                                ? 'Montante inválido.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: term,
                            decoration: InputDecoration(
                              labelText: shortTerm
                                  ? 'Prazo (dias)'
                                  : 'Prazo (meses)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              final value = int.tryParse(v ?? '');
                              if (value == null) return 'Prazo inválido.';
                              if (shortTerm) {
                                if (value < 1 || value > 14) {
                                  return 'Use um prazo entre 1 e 14 dias.';
                                }
                                return null;
                              }
                              final minMonths = productMonths(
                                'min_months',
                                fallback: 1,
                              );
                              final maxMonths = productMonths(
                                'max_months',
                                fallback: minMonths,
                              );
                              if (value < minMonths || value > maxMonths) {
                                return 'Use um prazo entre $minMonths e $maxMonths meses.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observações',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result != true) return;
    if (!mounted) return;
    try {
      final amountCents = (double.parse(amount.text) * 100).round();
      final termValue = int.parse(term.text);
      final months = shortTerm ? 1 : termValue;
      if (item == null) {
        final validClient = clientOptions.any(
          (entry) => entry.id == selectedClientId,
        );
        final validProduct = _products.any(
          (product) => '${product['id'] ?? ''}' == selectedProductId,
        );
        if (!validClient || !validProduct) {
          throw const ApiFailure('Cliente ou produto de crédito indisponível.');
        }
        await widget.repository.write('POST', '/requests', {
          'clientId': selectedClientId,
          'productId': selectedProductId,
          'amountCents': amountCents,
          'months': months,
          if (shortTerm) 'termDays': termValue,
        });
      } else {
        final product = _products.firstWhere(
          (row) => '${row['name'] ?? ''}' == item.product,
          orElse: () =>
              _products.isEmpty ? <String, dynamic>{} : _products.first,
        );
        if (product.isEmpty) {
          throw const ApiFailure('Produto de crédito indisponível.');
        }
        final conditions = [
          'Montante solicitado: $amountCents centavos',
          'Prazo: $months meses',
          if (notes.text.trim().isNotEmpty) notes.text.trim(),
        ].join('\n');
        await widget.repository.write('PATCH', '/requests/${item.id}/stage', {
          'stage': item.rawStage.isEmpty ? 'documentation' : item.rawStage,
          'reason': conditions,
          'version': item.version,
        });
      }
      await _load();
      if (context.mounted) {
        await showFeedbackDialog(
          context,
          title: 'Processo guardado',
          message: 'Processo confirmado pelo servidor.',
          success: true,
        );
      }
    } catch (failure) {
      if (context.mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível guardar',
          message: '$failure',
          success: false,
        );
      }
    }
  }

  static String _clientIdentifier(Map<dynamic, dynamic> row) {
    return _recordIdentifier(
      row,
      keys: const ['client_id', 'clientId', 'uuid', 'id'],
    );
  }

  static List<Map<dynamic, dynamic>> _rows(dynamic response) {
    if (response is List) {
      return response.whereType<Map>().toList(growable: false);
    }
    if (response is Map && response['data'] is List) {
      return (response['data'] as List).whereType<Map>().toList(
        growable: false,
      );
    }
    return const [];
  }

  static String _recordIdentifier(
    Map<dynamic, dynamic> row, {
    List<String> keys = const [
      'accountId',
      'account_id',
      'uuid',
      'value',
      'id',
    ],
  }) {
    for (final key in keys) {
      final raw = row[key];
      final value = raw is Map
          ? _recordIdentifier(raw, keys: keys)
          : '${raw ?? ''}'.trim();
      if (_isUuid(value)) return value;
    }
    for (final raw in row.values.whereType<Map>()) {
      final value = _recordIdentifier(raw, keys: keys);
      if (_isUuid(value)) return value;
    }
    return '';
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  Future<void> _openStageForm(BuildContext context, [_CreditCase? item]) async {
    if (widget.stage == 'credit-disbursement' && _accounts.isEmpty) {
      await showFeedbackDialog(
        context,
        title: 'Conta de desembolso indisponível',
        message:
            'O servidor não devolveu nenhuma conta de tesouraria válida. Configure uma conta de pagamento antes de efectuar o desembolso.',
        success: false,
      );
      return;
    }
    final specs = _stageFields(widget.stage, item);
    final availableProcesses = _stageProcesses;
    final controllers = <String, TextEditingController>{};
    final selections = <String, String>{};
    var selectedClient =
        item?.client ?? (_clients.isEmpty ? '' : _clients.first);
    var selectedProcess = item == null
        ? (availableProcesses.isEmpty ? '' : availableProcesses.first)
        : availableProcesses.firstWhere(
            (value) => value.startsWith(item.reference),
            orElse: () => item.reference,
          );
    _CreditCase? selectedCase() {
      final reference = selectedProcess.split(' · ').first.trim();
      return _cases.cast<_CreditCase?>().firstWhere(
        (candidate) => candidate?.reference == reference,
        orElse: () => item ?? selected,
      );
    }

    void syncDisbursementCase() {
      if (widget.stage != 'credit-disbursement') return;
      final target = selectedCase();
      if (target == null) return;
      selectedClient = target.client;
      controllers['amount']?.text = target.amount.toStringAsFixed(2);
    }

    var selectedResponsible = _authorizers.isEmpty ? '' : _authorizers.first;
    for (final field in specs) {
      if (field.clientPicker ||
          field.processPicker ||
          field.responsiblePicker) {
        selections[field.key] = field.initial;
      } else if (field.options != null) {
        selections[field.key] = field.initial.isNotEmpty
            ? field.initial
            : field.options!.keys.first;
      } else {
        controllers[field.key] = TextEditingController(text: field.initial);
      }
    }
    syncDisbursementCase();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(meta.icon, color: meta.color),
              const SizedBox(width: 10),
              Expanded(child: Text(meta.action)),
            ],
          ),
          content: SizedBox(
            width: 680,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _stageFormIntro(context, widget.stage),
                    const SizedBox(height: 18),
                    for (final field in specs) ...[
                      if (field.clientPicker)
                        _clientSelector(dialogContext, selectedClient, (value) {
                          selectedClient = value;
                          setDialogState(() {});
                        })
                      else if (field.processPicker)
                        _searchableSelector(
                          dialogContext,
                          selectedProcess,
                          availableProcesses,
                          widget.stage == 'credit-disbursement'
                              ? 'Cliente apto / processo'
                              : 'Processo / contrato',
                          (value) {
                            selectedProcess = value;
                            syncDisbursementCase();
                            setDialogState(() {});
                          },
                        )
                      else if (field.responsiblePicker)
                        _searchableSelector(
                          dialogContext,
                          selectedResponsible,
                          _authorizers,
                          'Responsável pela autorização',
                          (value) {
                            selectedResponsible = value;
                            setDialogState(() {});
                          },
                        )
                      else if (field.options != null)
                        DropdownButtonFormField<String>(
                          initialValue: selections[field.key],
                          isExpanded: true,
                          decoration: InputDecoration(labelText: field.label),
                          items: [
                            for (final option in field.options!.entries)
                              DropdownMenuItem(
                                value: option.key,
                                child: Text(option.value),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(
                                () => selections[field.key] = value,
                              );
                            }
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Seleccione uma opção.'
                              : null,
                        )
                      else
                        TextFormField(
                          controller: controllers[field.key],
                          readOnly:
                              widget.stage == 'credit-disbursement' &&
                              field.key == 'amount',
                          maxLines: field.multiline ? 3 : 1,
                          keyboardType: field.numeric
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: field.label,
                            alignLabelWithHint: field.multiline,
                          ),
                          validator: (value) =>
                              !field.optional &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Preencha este campo.'
                              : null,
                        ),
                      const SizedBox(height: 12),
                    ],
                    _stageFormInsight(context, widget.stage, controllers),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Guardar e continuar'),
            ),
          ],
        ),
      ),
    );
    final values = {
      for (final entry in controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    // The dialog route can still rebuild once during its closing animation.
    // Dispose after that frame so TextFormField never receives a dead
    // controller during the transition.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
    if (saved != true || !mounted) return;
    var loadingVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (loadingContext) => PopScope(
          canPop: false,
          child: const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16),
                Flexible(child: Text('A enviar a requisição…')),
              ],
            ),
          ),
        ),
      ).whenComplete(() => loadingVisible = false),
    );
    try {
      final selectedReference = selectedProcess.split(' · ').first.trim();
      final target =
          item ??
          _cases.cast<_CreditCase?>().firstWhere(
            (candidate) => candidate?.reference == selectedReference,
            orElse: () => selected,
          );
      if (target == null) {
        throw const ApiFailure('Seleccione um processo antes de continuar.');
      }
      if (!_isUuid(target.id)) {
        throw const ApiFailure(
          'O processo seleccionado não possui um identificador válido. Actualize a lista e seleccione-o novamente.',
        );
      }
      switch (widget.stage) {
        case 'financial-analysis':
          int cents(String key) =>
              ((double.tryParse(values[key] ?? '') ?? 0) * 100).round();
          final opinion = selections['opinion'] ?? 'conditional';
          await widget.repository.write(
            'POST',
            '/requests/${target.id}/financial-analysis',
            {
              'incomeCents': cents('income'),
              'expensesCents': cents('expenses'),
              'obligationsCents': cents('debt'),
              'opinion': opinion,
              'creditHistory': values['history'] ?? '',
              'guarantees': values['guarantees'] ?? '',
              if ((values['notes'] ?? '').isNotEmpty) 'notes': values['notes'],
              'version': target.version,
            },
          );
        case 'credit-approval':
          final decision = selections['decision'] == 'rejected'
              ? 'rejected'
              : 'approved';
          final reason = values['conditions'] ?? '';
          await widget.repository
              .write('PATCH', '/requests/${target.id}/stage', {
                'stage': decision,
                if (reason.isNotEmpty) 'reason': reason,
                'version': target.version,
              });
        case 'credit-authorization':
          final returned = selections['approval'] == 'returned';
          final notes = values['notes'] ?? '';
          await widget.repository
              .write('POST', '/requests/${target.id}/authorization', {
                'decision': returned ? 'returned' : 'authorized',
                if (notes.isNotEmpty) 'notes': notes,
                'version': target.version,
              });
        case 'credit-disbursement':
          final accountId = selections['account'];
          if (accountId == null || !_isUuid(accountId)) {
            throw const ApiFailure(
              'A conta de origem seleccionada é inválida. Seleccione-a novamente.',
            );
          }
          await widget.repository.write(
            'POST',
            '/requests/${target.id}/disburse',
            {'accountId': accountId},
          );
        case 'credit-restructuring':
          final term = int.tryParse(values['term'] ?? '') ?? 0;
          final monthlyRate = double.tryParse(values['rate'] ?? '') ?? -1;
          if (term < 1 || term > 360 || monthlyRate < 0) {
            throw const ApiFailure(
              'Introduza um prazo e uma taxa válidos para a reestruturação.',
            );
          }
          final principalCents = (target.amount * 100).round();
          if (principalCents < 1) {
            throw const ApiFailure(
              'O crédito seleccionado não possui capital válido.',
            );
          }
          final frequency = selections['frequency'] ?? 'monthly';
          final schedule = _restructuredSchedule(
            principalCents: principalCents,
            periods: term,
            monthlyRate: monthlyRate,
            frequency: frequency,
          );
          final reason = [
            _restructuringReason(selections['reason']),
            if ((values['justification'] ?? '').isNotEmpty)
              values['justification']!,
          ].join(' — ');
          await widget.repository.write('POST', '/loan-adjustments', {
            'loanId': target.id,
            'reason': reason,
            'previousSnapshot': {
              'principalCents': principalCents,
              'balanceCents': principalCents,
              'months': target.term,
              'status': target.rawStage,
            },
            'newSnapshot': {
              'principalCents': principalCents,
              'months': term,
              'monthlyRate': monthlyRate,
              'paymentFrequency': frequency,
              'schedule': schedule,
            },
          });
        default:
          throw const ApiFailure(
            'Esta etapa ainda não possui persistência remota disponível.',
          );
      }
      await _load();
      if (loadingVisible && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingVisible = false;
      }
      if (context.mounted) {
        await showFeedbackDialog(
          context,
          title: 'Registo guardado',
          message: '${meta.title} confirmada pelo servidor.',
          success: true,
        );
      }
    } catch (failure) {
      if (loadingVisible && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingVisible = false;
      }
      if (context.mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível guardar',
          message: '$failure',
          success: false,
        );
      }
    }
  }

  List<Json> _restructuredSchedule({
    required int principalCents,
    required int periods,
    required double monthlyRate,
    required String frequency,
  }) {
    final basePrincipal = principalCents ~/ periods;
    final remainder = principalCents % periods;
    var remaining = principalCents;
    final start = DateTime(2026, 9, 24);
    return [
      for (var index = 1; index <= periods; index++)
        () {
          final principal = basePrincipal + (index <= remainder ? 1 : 0);
          final interest = (remaining * monthlyRate / 100).round();
          remaining -= principal;
          final dueDate = switch (frequency) {
            'weekly' => start.add(Duration(days: index * 7)),
            'biweekly' => start.add(Duration(days: index * 14)),
            _ => DateTime(start.year, start.month + index, start.day),
          };
          return <String, dynamic>{
            'number': index,
            'dueDate': _dateOnly(dueDate),
            'principalCents': principal,
            'interestCents': interest,
          };
        }(),
    ];
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _restructuringReason(String? value) => switch (value) {
    'term' => 'Ajuste de prazo',
    'settlement' => 'Acordo de liquidação',
    _ => 'Dificuldade temporária',
  };

  Widget _clientSelector(
    BuildContext dialogContext,
    String selectedClient,
    ValueChanged<String> onSelected,
  ) => FormField<String>(
    initialValue: selectedClient,
    validator: (value) =>
        value == null || value.isEmpty ? 'Seleccione o cliente.' : null,
    builder: (field) => InkWell(
      onTap: () async {
        var query = '';
        final value = await showDialog<String>(
          context: dialogContext,
          builder: (pickerContext) => StatefulBuilder(
            builder: (pickerContext, pickerSetState) {
              final matches = _clients
                  .where(
                    (client) => client.toLowerCase().contains(
                      query.trim().toLowerCase(),
                    ),
                  )
                  .toList();
              return AlertDialog(
                title: const Text('Selecionar cliente'),
                content: SizedBox(
                  width: 460,
                  height: 360,
                  child: Column(
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar cliente',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            pickerSetState(() => query = value),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text('Nenhum cliente encontrado.'),
                              )
                            : ListView.separated(
                                itemCount: matches.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) => ListTile(
                                  leading: const Icon(Icons.person_outline),
                                  title: Text(matches[index]),
                                  selected: matches[index] == selectedClient,
                                  onTap: () => Navigator.pop(
                                    pickerContext,
                                    matches[index],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
        if (value != null) {
          field.didChange(value);
          onSelected(value);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Cliente',
          prefixIcon: const Icon(Icons.people_outline),
          errorText: field.errorText,
        ),
        child: Row(
          children: [
            Expanded(child: Text(selectedClient)),
            const Icon(Icons.search, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _searchableSelector(
    BuildContext dialogContext,
    String selected,
    List<String> options,
    String label,
    ValueChanged<String> onSelected,
  ) => FormField<String>(
    initialValue: selected,
    validator: (value) =>
        value == null || value.isEmpty ? 'Seleccione uma opção.' : null,
    builder: (field) => InkWell(
      onTap: () async {
        var query = '';
        final value = await showDialog<String>(
          context: dialogContext,
          builder: (pickerContext) => StatefulBuilder(
            builder: (pickerContext, pickerSetState) {
              final matches = options
                  .where(
                    (option) => option.toLowerCase().contains(
                      query.trim().toLowerCase(),
                    ),
                  )
                  .toList();
              return AlertDialog(
                title: Text('Selecionar $label'),
                content: SizedBox(
                  width: 500,
                  height: 360,
                  child: Column(
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Pesquisar $label',
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) =>
                            pickerSetState(() => query = value),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(
                                child: Text('Nenhum registo encontrado.'),
                              )
                            : ListView.separated(
                                itemCount: matches.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, index) => ListTile(
                                  leading: Icon(
                                    label.contains('Responsável')
                                        ? Icons.person_outline
                                        : Icons.description_outlined,
                                  ),
                                  title: Text(matches[index]),
                                  selected: matches[index] == selected,
                                  onTap: () => Navigator.pop(
                                    pickerContext,
                                    matches[index],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
        if (value != null) {
          field.didChange(value);
          onSelected(value);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            label.contains('Responsável')
                ? Icons.person_outline
                : label.contains('Processo') || label.contains('contrato')
                ? FluentSystemIcons.documentSearch
                : Icons.description_outlined,
          ),
          errorText: field.errorText,
        ),
        child: Row(
          children: [
            Expanded(child: Text(selected)),
            const Icon(Icons.search, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _stageFormIntro(BuildContext context, String stage) {
    final text = switch (stage) {
      'financial-analysis' =>
        'Registe evidências verificáveis para suportar o parecer de capacidade de pagamento.',
      'credit-approval' =>
        'Documente a decisão do comité e as condições aprovadas ou o motivo da rejeição.',
      'credit-authorization' =>
        'Confirme os controlos obrigatórios antes de libertar a operação para desembolso.',
      'credit-disbursement' =>
        'Prepare a transferência para a conta correta e confirme o comprovativo da operação.',
      'credit-status' =>
        'Abra o contrato para consultar condições, prestações, pagamentos e eventos de risco.',
      'credit-restructuring' =>
        'Altere as condições de um contrato existente preservando o histórico original.',
      _ => 'Preencha os dados da etapa para avançar o processo.',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.icon, color: meta.color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _stageFormInsight(
    BuildContext context,
    String stage,
    Map<String, TextEditingController> controllers,
  ) {
    final text = switch (stage) {
      'financial-analysis' =>
        'Indicadores: esforço financeiro, endividamento e cobertura da prestação serão recalculados ao sincronizar.',
      'credit-approval' =>
        'A decisão ficará associada ao utilizador autenticado e ao histórico de auditoria.',
      'credit-disbursement' =>
        'A operação só deve ser confirmada após validar saldo, conta de destino e comprovativo.',
      'credit-restructuring' =>
        'A nova prestação será comparada com a prestação atual antes da confirmação.',
      _ =>
        'Os dados guardados ficam disponíveis para a próxima etapa do ciclo.',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  List<_StageField> _stageFields(String stage, _CreditCase? item) {
    switch (stage) {
      case 'financial-analysis':
        return const [
          _StageField(
            'client',
            'Cliente / processo',
            initial: 'Adelino Armando de Sousa',
            clientPicker: true,
          ),
          _StageField(
            'income',
            'Rendimento mensal líquido (MT)',
            initial: '45000',
            numeric: true,
          ),
          _StageField(
            'expenses',
            'Despesas mensais (MT)',
            initial: '18500',
            numeric: true,
          ),
          _StageField(
            'debt',
            'Prestações de dívida existentes (MT)',
            initial: '6000',
            numeric: true,
          ),
          _StageField(
            'history',
            'Histórico de crédito',
            initial: 'Regular — sem incumprimentos relevantes',
          ),
          _StageField(
            'guarantees',
            'Garantias verificadas',
            initial: 'Avalista e declaração de rendimento',
          ),
          _StageField(
            'opinion',
            'Parecer do analista',
            options: {
              'favourable': 'Favorável',
              'conditional': 'Favorável com condições',
              'unfavourable': 'Desfavorável',
            },
          ),
          _StageField(
            'notes',
            'Justificação técnica',
            multiline: true,
            optional: true,
          ),
        ];
      case 'credit-approval':
        return const [
          _StageField(
            'client',
            'Cliente',
            initial: 'Adelino Armando de Sousa',
            clientPicker: true,
          ),
          _StageField(
            'process',
            'Processo para decisão',
            initial: 'CR-2026-0303',
            processPicker: true,
          ),
          _StageField(
            'decision',
            'Decisão',
            options: {
              'approved': 'Aprovar',
              'conditional': 'Aprovar com condições',
              'rejected': 'Rejeitar',
            },
          ),
          _StageField(
            'amount',
            'Montante aprovado (MT)',
            initial: '12500',
            numeric: true,
          ),
          _StageField(
            'term',
            'Prazo aprovado (meses)',
            initial: '6',
            numeric: true,
          ),
          _StageField(
            'rate',
            'Taxa mensal (%)',
            initial: '2.50',
            numeric: true,
          ),
          _StageField(
            'conditions',
            'Condições e deliberação',
            multiline: true,
            optional: true,
          ),
        ];
      case 'credit-authorization':
        return const [
          _StageField(
            'client',
            'Cliente',
            initial: 'Adelino Armando de Sousa',
            clientPicker: true,
          ),
          _StageField(
            'process',
            'Processo aprovado',
            initial: 'CR-2026-0303',
            processPicker: true,
          ),
          _StageField(
            'documents',
            'Documentação contratual',
            options: {'complete': 'Completa', 'pending': 'Pendente'},
          ),
          _StageField(
            'identity',
            'Identidade e KYC',
            options: {'verified': 'Validado', 'review': 'Em revisão'},
          ),
          _StageField(
            'approval',
            'Parecer de aprovação',
            options: {
              'confirmed': 'Confirmado',
              'returned': 'Devolvido para correcção',
            },
          ),
          _StageField(
            'authorizer',
            'Responsável pela autorização',
            initial: 'Gestor de Crédito',
            responsiblePicker: true,
          ),
          _StageField(
            'notes',
            'Observações formais',
            multiline: true,
            optional: true,
          ),
        ];
      case 'credit-disbursement':
        return [
          const _StageField(
            'contract',
            'Cliente apto / processo aprovado',
            processPicker: true,
          ),
          _StageField('account', 'Conta de origem', options: _accounts),
          const _StageField(
            'method',
            'Método de desembolso',
            options: {
              'transfer': 'Transferência bancária',
              'mpesa': 'M-Pesa',
              'emola': 'e-Mola',
              'cash': 'Numerário',
            },
          ),
          const _StageField(
            'amount',
            'Montante a desembolsar (MT)',
            numeric: true,
          ),
          const _StageField(
            'date',
            'Data de desembolso',
            initial: '22/09/2026',
          ),
          const _StageField(
            'fees',
            'Taxas administrativas (MT)',
            initial: '0',
            numeric: true,
          ),
          const _StageField(
            'receipt',
            'Comprovativo / referência externa',
            initial: 'A preencher após confirmação',
          ),
        ];
      case 'credit-status':
        return const [
          _StageField(
            'client',
            'Cliente',
            initial: 'Adelino Armando de Sousa',
            clientPicker: true,
          ),
          _StageField(
            'contract',
            'Contrato a abrir',
            initial: 'CR-2026-0303',
            processPicker: true,
          ),
          _StageField(
            'view',
            'Área do contrato',
            options: {
              'overview': 'Resumo e condições',
              'schedule': 'Plano de prestações',
              'payments': 'Pagamentos e recibos',
              'risk': 'Garantias e risco',
            },
          ),
          _StageField(
            'period',
            'Período de consulta',
            options: {'current': 'Ciclo actual', 'all': 'Todo o histórico'},
          ),
        ];
      case 'credit-restructuring':
        return const [
          _StageField(
            'client',
            'Cliente',
            initial: 'Júlio Custódio',
            clientPicker: true,
          ),
          _StageField(
            'contract',
            'Contrato existente',
            initial: 'CR-2026-0298',
            processPicker: true,
          ),
          _StageField(
            'reason',
            'Motivo da reestruturação',
            options: {
              'hardship': 'Dificuldade temporária',
              'term': 'Ajuste de prazo',
              'settlement': 'Acordo de liquidação',
            },
          ),
          _StageField(
            'capital',
            'Capital a reestruturar (MT)',
            initial: '18000',
            numeric: true,
          ),
          _StageField(
            'term',
            'Novo prazo (meses)',
            initial: '9',
            numeric: true,
          ),
          _StageField(
            'rate',
            'Nova taxa mensal (%)',
            initial: '2.00',
            numeric: true,
          ),
          _StageField(
            'frequency',
            'Frequência de pagamento',
            options: {
              'weekly': 'Semanal',
              'biweekly': 'Quinzenal',
              'monthly': 'Mensal',
            },
          ),
          _StageField(
            'justification',
            'Justificação e acordo com o cliente',
            multiline: true,
            optional: true,
          ),
        ];
      default:
        return const [];
    }
  }

  List<PopupMenuEntry<String>> _processActions(_CreditCase item) => [
    if (_canAdvance(item))
      const PopupMenuItem(value: 'advance', child: Text('Avançar etapa')),
    if (_canReject(item))
      const PopupMenuItem(value: 'archive', child: Text('Arquivar processo')),
  ];

  bool _canAdvance(_CreditCase item) => switch (item.rawStage) {
    'documentation' => [
      'guarantor',
      'analyst',
      'manager',
    ].contains(widget.role),
    'analysis' || 'committee' => ['analyst', 'manager'].contains(widget.role),
    _ => false,
  };

  bool _canReject(_CreditCase item) => switch (item.rawStage) {
    'documentation' => [
      'guarantor',
      'analyst',
      'manager',
    ].contains(widget.role),
    'analysis' || 'committee' => ['analyst', 'manager'].contains(widget.role),
    _ => false,
  };

  Future<void> _applyAction(_CreditCase item, String action) async {
    if (action == 'malparado' || action == 'revert') {
      await showFeedbackDialog(
        context,
        title: 'Acção indisponível',
        message:
            'Esta alteração deve ser realizada pelo fluxo de gestão do crédito.',
        kind: FeedbackKind.info,
      );
      return;
    }
    final nextStage = action == 'archive'
        ? 'rejected'
        : switch (item.rawStage) {
            'documentation' => 'analysis',
            'analysis' => 'committee',
            'committee' => 'approved',
            _ => null,
          };
    if (nextStage == null) return;
    final reason = action == 'archive'
        ? await _archiveReason(item)
        : 'Processo avançado pela operação ${meta.title.toLowerCase()}.';
    if (reason == null) return;
    try {
      await widget.repository.write('PATCH', '/requests/${item.id}/stage', {
        'stage': nextStage,
        'reason': reason,
        'version': item.version,
      });
      _clearFilters();
      await _load();
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: action == 'archive'
              ? 'Processo arquivado'
              : 'Processo avançado',
          message: action == 'archive'
              ? 'O processo foi encerrado e removido das filas operacionais.'
              : 'A próxima etapa já recebeu o processo.',
          success: true,
        );
      }
    } catch (failure) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Não foi possível actualizar',
          message: '$failure',
          success: false,
        );
      }
    }
  }

  Future<String?> _archiveReason(_CreditCase item) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arquivar processo?'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Motivo',
              helperText: item.reference,
            ),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? 'Indique o motivo do arquivamento.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    final reason = confirmed == true ? controller.text.trim() : null;
    Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
    return reason;
  }
}

class _CreditCase {
  _CreditCase(
    this.id,
    this.version,
    this.rawStage,
    this.reference,
    this.client,
    this.amount,
    this.term,
    this.owner,
    this.status,
    this.progress,
    this.attention,
    this.product,
    this.updated,
    this.notes,
  );
  final String id, rawStage;
  final int version;
  final String reference, client, owner, status, product, updated, notes;
  final double amount;
  final int term, progress;
  final bool attention;
  factory _CreditCase.fromJson(Map<String, dynamic> row, {required bool loan}) {
    final stage = '${row['stage'] ?? row['status'] ?? ''}';
    final progress = switch (stage) {
      'documentation' => 0,
      'analysis' => 1,
      'committee' => 2,
      'approved' => 4,
      'disbursed' || 'active' || 'paid' => 4,
      _ => 0,
    };
    final status = switch (stage) {
      'documentation' => 'Documentação',
      'analysis' => 'Em análise',
      'committee' => 'Em comité',
      'approved' => 'Aprovado',
      'rejected' => 'Recusado',
      'disbursed' => 'Concluído',
      'active' => 'Vigente',
      'paid' => 'Liquidado',
      'overdue' => 'Malparado',
      _ => stage.isEmpty ? 'Pendente' : stage,
    };
    final cents =
        num.tryParse(
          '${loan ? row['balance_cents'] ?? row['principal_cents'] : row['amount_cents']}',
        ) ??
        0;
    return _CreditCase(
      _CreditStagesViewState._recordIdentifier(
        row,
        keys: const [
          'request_id',
          'requestId',
          'credit_request_id',
          'creditRequestId',
          'uuid',
          'id',
        ],
      ),
      int.tryParse('${row['version'] ?? 1}') ?? 1,
      stage,
      '${row['number'] ?? row['id'] ?? ''}',
      '${row['client_name'] ?? row['name'] ?? 'Cliente'}',
      cents / 100,
      int.tryParse('${row['months'] ?? 0}') ?? 0,
      '${row['officer_name'] ?? row['created_by_name'] ?? 'Equipa de crédito'}',
      status,
      progress,
      ['rejected', 'overdue'].contains(stage),
      '${row['product_name'] ?? row['currency'] ?? 'Crédito'}',
      '${row['updated_at'] ?? row['created_at'] ?? ''}',
      '${row['reason'] ?? ''}',
    );
  }
  _CreditCase copyWith({
    String? status,
    bool? attention,
    int? progress,
    String? updated,
  }) => _CreditCase(
    id,
    version,
    rawStage,
    reference,
    client,
    amount,
    term,
    owner,
    status ?? this.status,
    progress ?? this.progress,
    attention ?? this.attention,
    product,
    updated ?? this.updated,
    notes,
  );
}

class _StageField {
  const _StageField(
    this.key,
    this.label, {
    this.initial = '',
    this.options,
    this.clientPicker = false,
    this.processPicker = false,
    this.responsiblePicker = false,
    this.numeric = false,
    this.multiline = false,
    this.optional = false,
  });
  final String key;
  final String label;
  final String initial;
  final Map<String, String>? options;
  final bool clientPicker;
  final bool processPicker;
  final bool responsiblePicker;
  final bool numeric;
  final bool multiline;
  final bool optional;
}

class _StageMeta {
  const _StageMeta(
    this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.color,
    this.statuses,
  );
  final String title, subtitle, action;
  final IconData icon;
  final Color color;
  final List<String> statuses;
}

const _stageMeta = <String, _StageMeta>{
  'financing': _StageMeta(
    'Financiamento',
    'Pedidos, contratos e condições comerciais do crédito.',
    'Novo financiamento',
    FluentSystemIcons.documentApproval,
    Color(0xFF16836A),
    ['Novo', 'Em análise', 'Aprovado', 'Concluído'],
  ),
  'financial-analysis': _StageMeta(
    'Análise financeira',
    'Avalie capacidade de pagamento, risco e evidências do cliente.',
    'Nova análise',
    FluentSystemIcons.analytics,
    Color(0xFF2672EC),
    ['Pendente', 'Em revisão', 'Parecer favorável', 'Concluído'],
  ),
  'credit-approval': _StageMeta(
    'Aprovar crédito',
    'Decisões de comité com trilho de auditoria e parecer documentado.',
    'Registar decisão',
    FluentSystemIcons.check,
    Color(0xFF0F7B6C),
    ['Pendente', 'Em comité', 'Aprovado', 'Rejeitado'],
  ),
  'credit-authorization': _StageMeta(
    'Autorizar crédito',
    'Submeta operações aprovadas para autorização final.',
    'Nova autorização',
    FluentSystemIcons.documentApproval,
    Color(0xFF6C4AB6),
    ['Pendente', 'Submetido', 'Autorizado', 'Devolvido'],
  ),
  'credit-disbursement': _StageMeta(
    'Desembolso',
    'Confirme conta, método, taxas e comprovativo antes de desembolsar.',
    'Preparar desembolso',
    FluentSystemIcons.payments,
    Color(0xFF0078D4),
    ['Pendente', 'Preparado', 'Desembolsado', 'Bloqueado'],
  ),
  'credit-status': _StageMeta(
    'Estado do crédito',
    'Acompanhe a carteira, prestações, garantias e histórico de cada contrato.',
    'Abrir contrato',
    FluentSystemIcons.wallet,
    Color(0xFF0F6CBD),
    ['Activo', 'Em atraso', 'Liquidado', 'Em risco'],
  ),
  'credit-restructuring': _StageMeta(
    'Reestruturação de crédito',
    'Simule novas condições e registe acordos com rastreabilidade.',
    'Nova reestruturação',
    FluentSystemIcons.flowChart,
    Color(0xFFCA5010),
    ['Pendente', 'Em simulação', 'Aprovado', 'Concluído'],
  ),
};
