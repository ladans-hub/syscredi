import '../../../core/widgets/premium_dialog.dart';
import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';

class CreditProductsView extends StatefulWidget {
  const CreditProductsView({super.key});
  @override
  State<CreditProductsView> createState() => _CreditProductsState();
}

class _CreditProductsState extends State<CreditProductsView> {
  String query = '';
  String status = 'Todos';
  final products = <_Product>[
    _Product(
      'Microcrédito Flex',
      'MC-FLX-01',
      'Pessoal',
      'Activo',
      'MZN',
      1000,
      50000,
      '30% anual',
      'Mensal',
      '1–12 meses',
      'Mensal',
    ),
    _Product(
      'Capital de Giro',
      'EMP-GIRO-02',
      'Empresarial',
      'Activo',
      'MZN',
      10000,
      250000,
      '28% anual',
      'Mensal',
      '3–24 meses',
      'Mensal',
    ),
    _Product(
      'Crédito Emergência',
      'EMG-001',
      'Emergência',
      'Rascunho',
      'MZN',
      500,
      15000,
      '2,5% mensal',
      'Mensal',
      '1–6 meses',
      'Quinzenal',
    ),
    _Product(
      'Crédito Grupo Solidário',
      'GRP-009',
      'Grupo',
      'Inactivo',
      'MZN',
      5000,
      100000,
      '24% anual',
      'Mensal',
      '6–18 meses',
      'Mensal',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = products
        .where(
          (p) =>
              (status == 'Todos' || p.status == status) &&
              ('${p.name} ${p.code} ${p.type}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.apps,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produtos de crédito',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Text(
                    'Configure ofertas, limites, juros e regras de elegibilidade.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _form(context),
              icon: const Icon(Icons.add),
              label: const Text('Novo produto'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Pesquisar produto, código ou tipo',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Activo', child: Text('Activos')),
                  DropdownMenuItem(value: 'Rascunho', child: Text('Rascunhos')),
                  DropdownMenuItem(value: 'Inactivo', child: Text('Inactivos')),
                ],
                onChanged: (v) => setState(() => status = v ?? 'Todos'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filtros'),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.sync),
              label: const Text('Ordenar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('PRODUTO')),
                DataColumn(label: Text('TIPO')),
                DataColumn(label: Text('ESTADO')),
                DataColumn(label: Text('LIMITES')),
                DataColumn(label: Text('JUROS')),
                DataColumn(label: Text('PRAZO')),
                DataColumn(label: Text('PAGAMENTO')),
                DataColumn(label: Text('ACÇÕES')),
              ],
              rows: [
                for (final p in visible)
                  DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              p.code,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(p.type)),
                      DataCell(_badge(p.status)),
                      DataCell(
                        Text(
                          '${p.min.toStringAsFixed(0)}–${p.max.toStringAsFixed(0)} ${p.currency}',
                        ),
                      ),
                      DataCell(Text(p.rate)),
                      DataCell(Text(p.term)),
                      DataCell(Text(p.frequency)),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Ver produto',
                              onPressed: () => _details(context, p),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: () => _form(context, product: p),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Simular',
                              onPressed: () => _simulate(context, p),
                              icon: const Icon(Icons.calculate_outlined),
                            ),
                            IconButton(
                              tooltip: 'Activar/desactivar',
                              onPressed: () => setState(
                                () => p.status = p.status == 'Activo'
                                    ? 'Inactivo'
                                    : 'Activo',
                              ),
                              icon: const Icon(Icons.sync),
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

  Widget _badge(String value) {
    final c = value == 'Activo'
        ? Colors.teal
        : value == 'Rascunho'
        ? Colors.orange
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        value,
        style: TextStyle(color: c, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _form(BuildContext context, {_Product? product}) async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: product?.name);
    final code = TextEditingController(text: product?.code);
    final min = TextEditingController(text: product?.min.toStringAsFixed(0));
    final max = TextEditingController(text: product?.max.toStringAsFixed(0));
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
        actionsPadding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
        title: Text(
          product == null
              ? 'Novo produto de crédito'
              : 'Editar produto de crédito',
        ),
        content: SizedBox(
          width: 760,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Identificação e descrição'),
                  _fields([
                    _field(name, 'Nome do produto'),
                    _field(code, 'Código único'),
                  ]),
                  _field(
                    TextEditingController(),
                    'Descrição comercial',
                    lines: 2,
                  ),
                  _section('Limites e juros'),
                  _fields([
                    _field(min, 'Montante mínimo'),
                    _field(max, 'Montante máximo'),
                    _select('Tipo de crédito', [
                      'Pessoal',
                      'Consumo',
                      'Empresarial',
                      'Emergência',
                      'Salário',
                      'Grupo',
                    ]),
                  ]),
                  _fields([
                    _select('Método de cálculo', [
                      'Juro flat',
                      'Saldo decrescente',
                      'Anuidade',
                    ]),
                    _select('Periodicidade da taxa', [
                      'Mensal',
                      'Trimestral',
                      'Anual',
                    ]),
                  ]),
                  _section('Prazo e prestações'),
                  _fields([
                    _select('Prazo mínimo', ['1 mês', '3 meses', '6 meses']),
                    _select('Prazo máximo', [
                      '6 meses',
                      '12 meses',
                      '24 meses',
                    ]),
                    _select('Frequência', ['Semanal', 'Quinzenal', 'Mensal']),
                  ]),
                  _fields([
                    _select('Carência', ['Sem carência', '15 dias', '30 dias']),
                    _select('Liquidação antecipada', [
                      'Permitida',
                      'Não permitida',
                    ]),
                  ]),
                  _section('Comissões, garantias e regras'),
                  _field(
                    TextEditingController(),
                    'Comissões e taxas (preparo, desembolso, selo)',
                  ),
                  _field(
                    TextEditingController(),
                    'Multas por atraso e configuração de mora',
                  ),
                  _field(
                    TextEditingController(),
                    'Garantias/avalistas exigidos',
                  ),
                  _field(
                    TextEditingController(),
                    'Critérios de elegibilidade e documentos obrigatórios',
                    lines: 3,
                  ),
                  _field(
                    TextEditingController(),
                    'Regras de aprovação e incumprimento',
                    lines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialog);
                _toast(context, 'Produto guardado.');
              }
            },
            child: const Text('Guardar produto'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 22, bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: .14),
      ),
    ),
    child: Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    ),
  );
  Widget _fields(List<Widget> children) =>
      Wrap(spacing: 16, runSpacing: 16, children: children);
  Widget _field(TextEditingController c, String label, {int lines = 1}) =>
      SizedBox(
        width: lines > 1 ? 540 : 260,
        child: TextFormField(
          controller: c,
          maxLines: lines,
          minLines: lines,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Obrigatório' : null,
          decoration: InputDecoration(labelText: label),
        ),
      );
  Widget _select(String label, List<String> values) => SizedBox(
    width: 260,
    child: DropdownButtonFormField<String>(
      initialValue: values.first,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in values)
          DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (_) {},
    ),
  );
  void _details(BuildContext c, _Product p) => showDialog<void>(
    context: c,
    builder: (dialog) => PremiumDialog(
      title: Text(p.name),
      subtitle: 'Produto de crédito · ${p.code}',
      icon: Icons.apps,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge(p.status),
          const SizedBox(height: 20),
          DetailFields(
            fields: [
              ('Tipo de crédito', p.type),
              ('Moeda', p.currency),
              ('Limites', '${p.min} – ${p.max} ${p.currency}'),
              ('Taxa', p.rate),
              ('Prazo', p.term),
              ('Frequência', p.frequency),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _simulate(c, p),
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Simular'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
  void _simulate(BuildContext c, _Product p) => showDialog<void>(
    context: c,
    builder: (dialog) => PremiumDialog(
      subtitle: 'Estimativa de crédito · Dados de demonstração',
      title: Text('Simulador · ${p.name}'),
      content: const Text(
        'Montante solicitado: 20 000 MZN\nJuros estimados: 5 000 MZN\nEncargos: 350 MZN\nTotal a pagar: 25 350 MZN\n12 prestações de 2 112,50 MZN\n\nPlano: 10/10/2026 · 2 112,50 MZN\n10/11/2026 · 2 112,50 MZN\n10/12/2026 · 2 112,50 MZN',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
  void _toast(BuildContext c, String m) => showFeedbackDialog(c, message: m);
}

class _Product {
  _Product(
    this.name,
    this.code,
    this.type,
    this.status,
    this.currency,
    this.min,
    this.max,
    this.rate,
    this.period,
    this.term,
    this.frequency,
  );
  final String name, code, type, currency, rate, period, term, frequency;
  String status;
  final double min, max;
}
