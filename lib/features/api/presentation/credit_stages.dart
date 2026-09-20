import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';

/// Operações de crédito agrupadas por etapa do ciclo de vida.
///
/// A página usa dados locais para manter o fluxo explorável mesmo quando o
/// ambiente ainda não tem dados remotos. As ações já alteram estado local e
/// servem como contrato visual para a integração com a API.
class CreditStagesView extends StatefulWidget {
  const CreditStagesView({required this.stage, super.key});
  final String stage;

  @override
  State<CreditStagesView> createState() => _CreditStagesViewState();
}

class _CreditStagesViewState extends State<CreditStagesView> {
  static const _clients = [
    'Adelino Armando de Sousa',
    'Júlio Custódio',
    'Francisco Adelino Rui',
    'Armando Manuel Antonio Munhangane',
    'Edson Mário Morais',
    'Elisabete Celeste Luis Piwalo',
  ];
  static const _processes = [
    'CR-2026-0303 · Adelino Armando de Sousa',
    'CR-2026-0298 · Júlio Custódio',
    'CR-2026-0287 · Francisco Adelino Rui',
    'CR-2026-0274 · Armando Manuel Antonio Munhangane',
  ];
  static const _authorizers = [
    'Naveia Muaquiquia João · Gestor de Crédito',
    'Marta João · Directora de Operações',
    'Celso Macuácua · Comité de Crédito',
  ];
  late final List<_CreditCase> _cases = _seed(widget.stage);
  String filter = 'Todos';
  String query = '';
  _CreditCase? selected;

  _StageMeta get meta => _stageMeta[widget.stage] ?? _stageMeta['financing']!;

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
          '${amount.toStringAsFixed(0)} MT',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
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
                onPressed: () => setState(() {
                  query = '';
                  filter = 'Todos';
                }),
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
          if (visible.isEmpty)
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
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar cliente ou contrato',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => query = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    filter = 'Todos';
                    query = '';
                  }),
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
                        DataCell(Text('${item.amount.toStringAsFixed(2)} MT')),
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
          DataCell(Text('${item.amount.toStringAsFixed(2)} MT')),
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
                PopupMenuButton<String>(
                  onSelected: (value) => _applyAction(item, value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'advance',
                      child: Text('Avançar etapa'),
                    ),
                    const PopupMenuItem(
                      value: 'hold',
                      child: Text('Colocar em revisão'),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Arquivar processo'),
                    ),
                  ],
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
              _detail('Montante', '${item.amount.toStringAsFixed(2)} MT'),
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
                  OutlinedButton.icon(
                    onPressed: () => _applyAction(item, 'archive'),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Excluir'),
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
    var selectedClient = item?.client ?? _clients.first;
    final amount = TextEditingController(
      text: item?.amount.toStringAsFixed(2) ?? '12500',
    );
    final term = TextEditingController(text: item?.term.toString() ?? '6');
    final notes = TextEditingController(text: item?.notes ?? '');
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
                      initialValue: selectedClient,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Seleccione o cliente.'
                          : null,
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
                                                          matches[index],
                                                        ),
                                                        selected:
                                                            matches[index] ==
                                                            selectedClient,
                                                        onTap: () =>
                                                            Navigator.pop(
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
                            selectedClient = value;
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
                            decoration: const InputDecoration(
                              labelText: 'Prazo (meses)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => int.tryParse(v ?? '') == null
                                ? 'Prazo inválido.'
                                : null,
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
    final updated = _CreditCase(
      item?.reference ?? 'FIN-${1000 + _cases.length}',
      selectedClient,
      double.parse(amount.text),
      int.parse(term.text),
      item?.owner ?? 'Naveia Muaquiquia',
      item?.status ?? meta.statuses.first,
      item?.progress ?? 0,
      item?.attention ?? true,
      item?.product ?? 'Microcrédito Crescer',
      'Hoje',
      notes.text.trim(),
    );
    setState(() {
      if (item == null) {
        _cases.insert(0, updated);
      } else {
        final index = _cases.indexOf(item);
        if (index >= 0) _cases[index] = updated;
        selected = updated;
      }
    });
    await showFeedbackDialog(
      context,
      title: 'Processo guardado',
      message: 'Processo guardado localmente.',
      success: true,
    );
  }

  Future<void> _openStageForm(BuildContext context, [_CreditCase? item]) async {
    final specs = _stageFields(widget.stage, item);
    var selectedClient = item?.client ?? _clients.first;
    var selectedProcess = _processes.first;
    var selectedResponsible = _authorizers.first;
    final controllers = <String, TextEditingController>{};
    final selections = <String, String>{};
    for (final field in specs) {
      if (field.clientPicker ||
          field.processPicker ||
          field.responsiblePicker ||
          field.options != null) {
        selections[field.key] = field.initial.isNotEmpty
            ? field.initial
            : field.options!.keys.first;
      } else {
        controllers[field.key] = TextEditingController(text: field.initial);
      }
    }
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
                          _processes,
                          'Processo / contrato',
                          (value) {
                            selectedProcess = value;
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
                          maxLines: field.multiline ? 3 : 1,
                          keyboardType: field.numeric
                              ? TextInputType.number
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: field.label,
                            alignLabelWithHint: field.multiline,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
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
    // The dialog route can still rebuild once during its closing animation.
    // Dispose after that frame so TextFormField never receives a dead
    // controller during the transition.
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });
    if (saved != true || !mounted) return;
    await showFeedbackDialog(
      context,
      title: 'Registo guardado',
      message: '${meta.title} registada localmente.',
      success: true,
    );
  }

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
          _StageField('notes', 'Justificação técnica', multiline: true),
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
          _StageField('conditions', 'Condições e deliberação', multiline: true),
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
          _StageField('notes', 'Observações formais', multiline: true),
        ];
      case 'credit-disbursement':
        return const [
          _StageField(
            'client',
            'Cliente',
            initial: 'Adelino Armando de Sousa',
            clientPicker: true,
          ),
          _StageField(
            'contract',
            'Contrato autorizado',
            initial: 'CR-2026-0303',
            processPicker: true,
          ),
          _StageField(
            'account',
            'Conta de origem',
            options: {
              'main': 'Conta operacional · 0031',
              'cash': 'Caixa principal',
            },
          ),
          _StageField(
            'method',
            'Método de desembolso',
            options: {
              'transfer': 'Transferência bancária',
              'mpesa': 'M-Pesa',
              'emola': 'e-Mola',
              'cash': 'Numerário',
            },
          ),
          _StageField(
            'amount',
            'Montante a desembolsar (MT)',
            initial: '12500',
            numeric: true,
          ),
          _StageField('date', 'Data de desembolso', initial: '20/09/2026'),
          _StageField(
            'fees',
            'Taxas administrativas (MT)',
            initial: '0',
            numeric: true,
          ),
          _StageField(
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
          ),
        ];
      default:
        return const [];
    }
  }

  void _applyAction(_CreditCase item, String action) {
    setState(() {
      final index = _cases.indexOf(item);
      if (index < 0) return;
      final next = action == 'malparado'
          ? 'Malparado'
          : action == 'revert'
          ? 'Vigente'
          : action == 'archive'
          ? 'Arquivado'
          : action == 'hold'
          ? 'Em revisão'
          : 'Concluído';
      _cases[index] = item.copyWith(
        status: next,
        attention: action == 'hold',
        progress: action == 'advance'
            ? (item.progress + 1).clamp(0, 4)
            : item.progress,
        updated: 'Agora',
      );
      selected = _cases[index];
    });
  }

  static List<_CreditCase> _seed(String stage) {
    final config = _stageMeta[stage] ?? _stageMeta['financing']!;
    return [
      _CreditCase(
        'CR-2026-0303',
        'Adelino Armando de Sousa',
        5640,
        3,
        'Naveia Muaquiquia',
        config.statuses.first,
        2,
        true,
        'Linha Crescer',
        'Hoje',
        'Documentos de rendimento pendentes.',
      ),
      _CreditCase(
        'CR-2026-0298',
        'Júlio Custódio',
        25000,
        6,
        'Marta João',
        config.statuses.length > 1 ? config.statuses[1] : config.statuses.first,
        3,
        false,
        'Microcrédito Comércio',
        'Ontem',
        'Cliente regular.',
      ),
      _CreditCase(
        'CR-2026-0287',
        'Francisco Adelino Rui',
        12500,
        4,
        'Naveia Muaquiquia',
        'Concluído',
        4,
        false,
        'Linha Agro',
        '08/09/2026',
        'Análise concluída com parecer favorável.',
      ),
      _CreditCase(
        'CR-2026-0274',
        'Armando Manuel Antonio Munhangane',
        5000,
        1,
        'Celso Macuácua',
        config.statuses.first,
        1,
        true,
        'Microcrédito Rápido',
        '07/09/2026',
        'Aguardando validação documental.',
      ),
    ];
  }
}

class _CreditCase {
  _CreditCase(
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
  final String reference, client, owner, status, product, updated, notes;
  final double amount;
  final int term, progress;
  final bool attention;
  _CreditCase copyWith({
    String? status,
    bool? attention,
    int? progress,
    String? updated,
  }) => _CreditCase(
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
