import '../../../core/widgets/premium_dialog.dart';
import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({required this.area, super.key});
  final String area;
  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  String query = '';
  String filter = 'Todos';
  final categories = <String>[
    'Operações',
    'Prestação',
    'Taxas',
    'Renda',
    'Equipamento',
    'Transporte',
    'Outros',
  ];
  late final _FinanceConfig config =
      _configs[widget.area] ?? _configs['Saldos']!;
  @override
  Widget build(BuildContext context) {
    final rows = config.rows
        .where((r) => filter == 'Todos' || r[2] == filter)
        .where(
          (r) =>
              query.isEmpty ||
              r.join(' ').toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              config.icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(config.subtitle),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _form(context),
              icon: const Icon(Icons.add),
              label: Text(config.action),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in config.metrics)
              _metric(context, metric[0], metric[1], metric[2]),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 290,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText:
                              'Pesquisar operação, cliente ou referência',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: filter,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: [
                          for (final v in ['Todos', ...config.statuses])
                            DropdownMenuItem(value: v, child: Text(v)),
                        ],
                        onChanged: (v) => setState(() => filter = v ?? 'Todos'),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        query = '';
                        filter = 'Todos';
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_alt_outlined),
                      label: const Text('Filtros'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      for (final h in config.headers)
                        DataColumn(label: Text(h)),
                    ]..add(const DataColumn(label: Text('ACÇÕES'))),
                    rows: [
                      for (final row in rows)
                        DataRow(
                          cells: [
                            for (final value in row) DataCell(Text(value)),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Ver detalhe',
                                    onPressed: () => _details(context, row),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  if (config.editable)
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () => _form(context, row: row),
                                      icon: const Icon(Icons.edit),
                                    ),
                                ],
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
        ),
      ],
    );
  }

  Widget _metric(BuildContext c, String label, String value, String icon) =>
      SizedBox(
        width: 220,
        child: Card(
          child: ListTile(
            leading: Icon(
              _metricIcon(icon),
              color: Theme.of(c).colorScheme.primary,
            ),
            title: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(label),
          ),
        ),
      );
  IconData _metricIcon(String name) => switch (name) {
    'warning' => Icons.warning_amber_rounded,
    'pending' => Icons.pending,
    'check' => Icons.check_circle_outline,
    'people' => Icons.people_outline,
    'interest' => Icons.analytics,
    'up' => Icons.trending_up_rounded,
    'asset' => Icons.apps,
    _ => Icons.attach_money_rounded,
  };
  void _details(BuildContext c, List<String> row) => showDialog<void>(
    context: c,
    builder: (dialog) => PremiumDialog(
      title: Text('${config.title} · detalhe'),
      subtitle: 'Informação financeira · Registo demonstrativo',
      icon: config.icon,
      content: DetailFields(
        fields: [
          for (var i = 0; i < row.length; i++)
            (
              config.headers.length > i ? config.headers[i] : 'Campo ${i + 1}',
              row[i],
            ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _toast(c, 'Exportação preparada.'),
          icon: const Icon(Icons.download),
          label: const Text('Exportar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
  void _form(BuildContext c, {List<String>? row}) => showDialog<void>(
    context: c,
    builder: (dialog) => AlertDialog(
      title: Text(
        row == null
            ? 'Novo registo · ${config.title}'
            : 'Editar registo · ${config.title}',
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final label in config.formFields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: label.toLowerCase().contains('categoria')
                    ? Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: categories.first,
                              decoration: InputDecoration(labelText: label),
                              items: [
                                for (final category in categories)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                              ],
                              onChanged: (_) {},
                            ),
                          ),
                          IconButton(
                            tooltip: 'Adicionar categoria',
                            onPressed: () => _addCategory(c),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      )
                    : TextFormField(
                        decoration: InputDecoration(labelText: label),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialog);
            _toast(c, 'Registo guardado com auditoria.');
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  void _toast(BuildContext c, String text) =>
      showFeedbackDialog(c, message: text);
  Future<void> _addCategory(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty && !categories.contains(value))
      setState(() => categories.add(value));
  }
}

class _FinanceConfig {
  const _FinanceConfig(
    this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.metrics,
    this.headers,
    this.rows,
    this.statuses,
    this.formFields, {
    this.editable = true,
  });
  final String title, subtitle, action;
  final IconData icon;
  final List<List<String>> metrics, rows;
  final List<String> headers, statuses, formFields;
  final bool editable;
}

const _configs = <String, _FinanceConfig>{
  'Saldos': _FinanceConfig(
    'Saldos',
    'Visão consolidada de caixa, bancos e carteira.',
    'Adicionar saldo',
    Icons.account_balance_wallet_outlined,
    [
      ['Disponível', '596 064 MT', 'wallet'],
      ['Bancos', '877 760 MT', 'bank'],
      ['Carteira', '1 248 600 MT', 'loan'],
      ['Pendentes', '42 800 MT', 'pending'],
    ],
    ['Conta', 'Nome', 'Estado', 'Valor'],
    [
      ['001', 'Conta operacional', 'Activo', '596 064 MT'],
      ['002', 'E-Mola 1', 'Activo', '596 065 MT'],
      ['003', 'E-Mola 2', 'Activo', '417 875 MT'],
    ],
    ['Activo', 'Suspenso'],
    ['Conta financeira', 'Nome da conta', 'Saldo inicial', 'Observações'],
  ),
  'Estornos': _FinanceConfig(
    'Estornos',
    'Rastreabilidade de operações revertidas.',
    'Registar estorno',
    Icons.undo_outlined,
    [
      ['Estornados', '6', 'undo'],
      ['Montante', '18 450 MT', 'money'],
      ['Pendentes', '2', 'pending'],
      ['Auditados', '100%', 'check'],
    ],
    ['Operação original', 'Motivo', 'Estado', 'Valor', 'Responsável'],
    [
      ['PG-2026-0182', 'Duplicação', 'Concluído', '750 MT', 'Marta João'],
      [
        'PG-2026-0171',
        'Pagamento inválido',
        'Pendente',
        '1 250 MT',
        'Celso Macuácua',
      ],
    ],
    ['Concluído', 'Pendente'],
    [
      'Referência original',
      'Motivo obrigatório',
      'Valor',
      'Responsável',
      'Evidência',
    ],
  ),
  'Receitas': _FinanceConfig(
    'Receitas',
    'Entradas financeiras por categoria e origem.',
    'Nova receita',
    Icons.trending_up_rounded,
    [
      ['Este mês', '84 500 MT', 'money'],
      ['Recebimentos', '64', 'payments'],
      ['Juros', '21 600 MT', 'interest'],
      ['Taxas', '8 450 MT', 'fee'],
    ],
    ['Data', 'Categoria', 'Estado', 'Cliente / origem', 'Valor'],
    [
      [
        '11/09/2026',
        'Prestação',
        'Confirmado',
        'Adelino Armando',
        '1 501,84 MT',
      ],
      ['12/09/2026', 'Taxa', 'Confirmado', 'CR-2026-0298', '350 MT'],
    ],
    ['Confirmado', 'Pendente'],
    ['Categoria', 'Cliente/crédito', 'Método', 'Valor', 'Comprovativo'],
  ),
  'Despesas': _FinanceConfig(
    'Despesas',
    'Custos operacionais e pagamentos a beneficiários.',
    'Nova despesa',
    Icons.trending_up_rounded,
    [
      ['Este mês', '32 700 MT', 'money'],
      ['Pendentes', '4', 'pending'],
      ['Aprovadas', '18', 'check'],
      ['Centros de custo', '6', 'cost'],
    ],
    ['Data', 'Categoria', 'Beneficiário', 'Estado', 'Valor'],
    [
      ['10/09/2026', 'Operações', 'M-Pesa', 'Aprovada', '3 500 MT'],
      ['14/09/2026', 'Renda', 'Imobiliária Maputo', 'Pendente', '12 000 MT'],
    ],
    ['Aprovada', 'Pendente', 'Rejeitada'],
    ['Categoria', 'Beneficiário', 'Centro de custo', 'Valor', 'Comprovativo'],
  ),
  'Desembolsos': _FinanceConfig(
    'Desembolsos',
    'Créditos aprovados preparados para libertação.',
    'Novo desembolso',
    Icons.payments_outlined,
    [
      ['Por desembolsar', '28 600 MT', 'pending'],
      ['Confirmados', '42', 'check'],
      ['Este mês', '128 450 MT', 'money'],
      ['Pendências', '3', 'warning'],
    ],
    ['Cliente', 'Contrato', 'Produto', 'Método', 'Estado', 'Valor'],
    [
      [
        'Júlio Custódio',
        'CR-2026-0298',
        'Flex',
        'E-Mola',
        'Pendente',
        '2 500 MT',
      ],
      [
        'Adelino Armando',
        'CR-2026-0303',
        'Empresarial',
        'Transferência',
        'Confirmado',
        '5 640 MT',
      ],
    ],
    ['Pendente', 'Confirmado', 'Cancelado'],
    [
      'Cliente/contrato',
      'Conta de origem',
      'Método',
      'Montante',
      'Comprovativo',
    ],
  ),
  'Reembolsos': _FinanceConfig(
    'Reembolsos',
    'Pagamentos de clientes e liquidação de prestações.',
    'Registar pagamento',
    Icons.receipt_long_outlined,
    [
      ['Recebido', '84 500 MT', 'money'],
      ['Prestações', '64', 'payments'],
      ['Juros', '21 600 MT', 'interest'],
      ['Em atraso', '9', 'warning'],
    ],
    ['Cliente', 'Crédito', 'Prestação', 'Capital', 'Juros', 'Total'],
    [
      [
        'Adelino Armando',
        'CR-2026-0303',
        '1/1',
        '5,64 MT',
        '1,69 MT',
        '7,48 MT',
      ],
      ['Francisco Adelino', 'CR-2026-0301', '1/1', '750 MT', '0 MT', '750 MT'],
    ],
    ['Confirmado', 'Pendente'],
    [
      'Cliente/crédito',
      'Data',
      'Conta',
      'Forma de pagamento',
      'Valor',
      'Comprovativo',
    ],
  ),
  'Prestações Vencidas': _FinanceConfig(
    'Prestações vencidas',
    'Carteira em atraso e ações de cobrança.',
    'Registar cobrança',
    Icons.warning_amber_rounded,
    [
      ['Em atraso', '18 240 MT', 'warning'],
      ['Clientes', '9', 'people'],
      ['Mora', '1 840 MT', 'interest'],
      ['Recuperação', '78,4%', 'up'],
    ],
    ['Cliente', 'Crédito', 'Dias atraso', 'Vencido', 'Mora', 'Risco'],
    [
      [
        'Adelino Armando',
        'CR-2026-0303',
        '11',
        '1 501,84 MT',
        '0,15 MT',
        'Médio',
      ],
      ['Júlio Custódio', 'CR-2026-0298', '28', '7 480 MT', '1 120 MT', 'Alto'],
    ],
    ['Alto', 'Médio', 'Baixo'],
    [
      'Cliente/crédito',
      'Contacto realizado',
      'Promessa',
      'Próxima ação',
      'Observações',
    ],
  ),
  'Ativos': _FinanceConfig(
    'Ativos',
    'Ativos financeiros e patrimoniais da instituição.',
    'Adicionar ativo',
    Icons.apps,
    [
      ['Valor total', '1 840 000 MT', 'money'],
      ['Ativos', '38', 'asset'],
      ['Em uso', '32', 'check'],
      ['Depreciação', '8,2%', 'down'],
    ],
    ['Código', 'Ativo', 'Categoria', 'Estado', 'Valor', 'Responsável'],
    [
      [
        'AT-001',
        'Viatura Toyota Hilux',
        'Transporte',
        'Em uso',
        '850 000 MT',
        'Operações',
      ],
      [
        'AT-014',
        'Computadores',
        'Equipamento',
        'Em uso',
        '240 000 MT',
        'Tecnologia',
      ],
    ],
    ['Em uso', 'Disponível', 'Baixado'],
    [
      'Nome do ativo',
      'Categoria',
      'Valor de aquisição',
      'Localização',
      'Responsável',
      'Estado',
    ],
  ),
};
