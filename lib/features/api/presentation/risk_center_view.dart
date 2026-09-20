import '../../../core/widgets/premium_dialog.dart';
import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/fluent_design.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../domain/money.dart';
import '../domain/repository.dart';

/// Monitoring uses only supplied observations; missing values are never zeroed.
class RiskCenterView extends StatefulWidget {
  const RiskCenterView({required this.rows, super.key});
  final List<Json> rows;

  @override
  State<RiskCenterView> createState() => _RiskCenterViewState();
}

class _RiskCenterViewState extends State<RiskCenterView> {
  final _search = TextEditingController();
  String _bucket = 'Todas';
  bool _priority = false;
  int _page = 0;
  static const _buckets = [
    'Em dia',
    '1–30 dias',
    '31–60 dias',
    '61–90 dias',
    'Mais de 90 dias',
    'Sem informação',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RiskCenterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) _page = 0;
  }

  int? _number(Json r, String key) {
    final value = int.tryParse('${r[key] ?? ''}');
    return value != null && value >= 0 ? value : null;
  }

  String _band(Json r) {
    final days = _number(r, 'days_past_due');
    if (days == null) return 'Sem informação';
    if (days == 0) return 'Em dia';
    if (days <= 30) return '1–30 dias';
    if (days <= 60) return '31–60 dias';
    if (days <= 90) return '61–90 dias';
    return 'Mais de 90 dias';
  }

  bool _alert(Json r) =>
      (_number(r, 'days_past_due') ?? 0) > 30 || r['restructured'] == true;
  String _value(Json r, String key) => '${r[key] ?? 'Não informado'}';
  String _amount(Json r) => _number(r, 'balance_cents') == null
      ? 'Não informado'
      : money(r['balance_cents']);
  String _action(Json r) {
    final days = _number(r, 'days_past_due');
    if (days == null) return 'Completar dados de acompanhamento';
    if (days > 90) return 'Rever estratégia de recuperação e garantias';
    if (days > 30) {
      return 'Reavaliar capacidade de pagamento e plano de cobrança';
    }
    if (days > 0) return 'Contactar cliente e confirmar regularização';
    if (r['restructured'] == true) return 'Acompanhar cumprimento do acordo';
    return 'Manter acompanhamento periódico';
  }

  Color _color(Json r) {
    final days = _number(r, 'days_past_due');
    final colors = Theme.of(context).colorScheme;
    return days == null
        ? colors.onSurfaceVariant
        : days > 30
        ? colors.error
        : days > 0
        ? const Color(0xff9a6200)
        : colors.primary;
  }

  void _details(Json row) => showDialog<void>(
    context: context,
    builder: (context) => PremiumDialog(
      title: const Text('Análise de risco'),
      subtitle: 'Avaliação de risco · ${_value(row, 'client_name')}',
      icon: Icons.policy_outlined,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailFields(
            fields: [
              ('Cliente', _value(row, 'client_name')),
              ('Referência', _value(row, 'client_id')),
              ('Contrato', _value(row, 'loan_id')),
              ('Capital em aberto', _amount(row)),
              ('Atraso', _band(row)),
              ('Classificação interna', _value(row, 'band')),
              ('Pontuação fornecida', _value(row, 'score')),
              ('Responsável', _value(row, 'officer_name')),
              ('Última avaliação', _value(row, 'assessed_at')),
              (
                'Reestruturado',
                row['restructured'] == null
                    ? 'Não informado'
                    : row['restructured'] == true
                    ? 'Sim'
                    : 'Não',
              ),
              ('Próxima acção sugerida', _action(row)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'A pontuação depende do modelo de origem. As faixas de atraso são operacionais e não substituem a avaliação de crédito ou a classificação regulamentar.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );

  Widget _surface(Widget child) =>
      FluentSurface(padding: const EdgeInsets.all(20), child: child);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = widget.rows;
    final complete =
        rows.isNotEmpty &&
        rows.every(
          (r) =>
              _number(r, 'balance_cents') != null &&
              _number(r, 'days_past_due') != null,
        );
    final total = rows.fold<int>(
      0,
      (sum, r) => sum + (_number(r, 'balance_cents') ?? 0),
    );
    String par(int threshold) {
      if (!complete || total == 0) return '—';
      final atRisk = rows
          .where((r) => _number(r, 'days_past_due')! > threshold)
          .fold<int>(0, (sum, r) => sum + _number(r, 'balance_cents')!);
      return '${(100 * atRisk / total).toStringAsFixed(1).replaceAll('.', ',')}%';
    }

    final query = _search.text.trim().toLowerCase();
    final filtered =
        rows
            .where(
              (r) =>
                  (_bucket == 'Todas' || _band(r) == _bucket) &&
                  (!_priority || _alert(r)) &&
                  '${r['client_name']} ${r['client_id']} ${r['loan_id']}'
                      .toLowerCase()
                      .contains(query),
            )
            .toList()
          ..sort(
            (a, b) => (_number(b, 'days_past_due') ?? -1).compareTo(
              _number(a, 'days_past_due') ?? -1,
            ),
          );
    final pages = (filtered.length / 10).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final shown = filtered.skip(page * 10).take(10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              FluentSystemIcons.shieldAlert,
              color: theme.colorScheme.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Central de risco',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const Text(
                    'Identifique sinais de alerta e acompanhe a qualidade do crédito.',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rows.any((r) => r['demo'] == true)
                    ? 'Ambiente de demonstração · dados fictícios'
                    : 'Monitorização interna',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Indicadores dos ${rows.length} registos carregados, antes dos filtros. Não representam necessariamente a carteira completa nem uma consulta a uma central externa.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 500
                ? 2
                : 1;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final item in [
                  (
                    'Capital em aberto',
                    rows.isNotEmpty &&
                            rows.every(
                              (r) => _number(r, 'balance_cents') != null,
                            )
                        ? money(total)
                        : '—',
                    'Soma dos saldos de capital',
                  ),
                  (
                    'PAR > 30 dias',
                    par(30),
                    'Capital com atraso superior a 30 dias',
                  ),
                  (
                    'PAR > 90 dias',
                    par(90),
                    'Capital com atraso superior a 90 dias',
                  ),
                  (
                    'Atenção prioritária',
                    '${rows.where(_alert).length}',
                    'Atraso > 30 dias ou reestruturação',
                  ),
                ])
                  SizedBox(
                    width: width,
                    child: _surface(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: theme.textTheme.labelLarge),
                          const SizedBox(height: 10),
                          Text(item.$2, style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 6),
                          Text(item.$3, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribuição por atraso',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'PAR = capital em aberto dos contratos acima do limiar / capital total. Sem dados completos, o indicador fica indisponível.',
              ),
              const SizedBox(height: 16),
              for (final bucket in _buckets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 118, child: Text(bucket)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: rows.isEmpty
                              ? 0
                              : rows.where((r) => _band(r) == bucket).length /
                                    rows.length,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${rows.where((r) => _band(r) == bucket).length}',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _surface(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Exposições em acompanhamento',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: c.maxWidth < 320 ? c.maxWidth : 320,
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar cliente ou contrato',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setState(() => _page = 0),
                      ),
                    ),
                    SizedBox(
                      width: c.maxWidth < 210 ? c.maxWidth : 210,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        key: ValueKey(_bucket),
                        initialValue: _bucket,
                        decoration: const InputDecoration(
                          labelText: 'Faixa de atraso',
                        ),
                        items: ['Todas', ..._buckets]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _bucket = v ?? 'Todas';
                          _page = 0;
                        }),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Apenas prioritários'),
                      selected: _priority,
                      onSelected: (v) => setState(() {
                        _priority = v;
                        _page = 0;
                      }),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _bucket = 'Todas';
                        _priority = false;
                        _page = 0;
                      }),
                      child: const Text('Limpar filtros'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    rows.isEmpty
                        ? 'Sem avaliações de risco disponíveis'
                        : 'Nenhum resultado para os filtros seleccionados',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Cliente / contrato')),
                      DataColumn(
                        label: Text('Capital em aberto'),
                        numeric: true,
                      ),
                      DataColumn(label: Text('Atraso')),
                      DataColumn(label: Text('Classificação')),
                      DataColumn(label: Text('Sinal de alerta')),
                      DataColumn(label: Text('Análise')),
                    ],
                    rows: shown
                        .map(
                          (r) => DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_value(r, 'client_name')),
                                    Text(
                                      _value(r, 'loan_id'),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(Text(_amount(r))),
                              DataCell(
                                Text(
                                  _band(r),
                                  style: TextStyle(
                                    color: _color(r),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(Text(_value(r, 'band'))),
                              DataCell(
                                Text(
                                  r['restructured'] == true
                                      ? 'Reestruturado'
                                      : (_number(r, 'days_past_due') ?? 0) > 30
                                      ? 'Rever capacidade de pagamento'
                                      : _number(r, 'days_past_due') == null
                                      ? 'Dados incompletos'
                                      : '—',
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  tooltip: 'Ver análise de risco',
                                  onPressed: () => _details(r),
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(
                    '${filtered.length} resultados · ordenados por maior atraso',
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Página anterior',
                        onPressed: page > 0
                            ? () => setState(() => _page = page - 1)
                            : null,
                        icon: const Icon(Icons.arrowBack),
                      ),
                      Text('${pages == 0 ? 0 : page + 1} / $pages'),
                      IconButton(
                        tooltip: 'Página seguinte',
                        onPressed: page + 1 < pages
                            ? () => setState(() => _page = page + 1)
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
