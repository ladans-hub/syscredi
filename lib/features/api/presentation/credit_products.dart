import '../../../core/widgets/premium_dialog.dart';
import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../domain/repository.dart';

class CreditProductsView extends StatefulWidget {
  const CreditProductsView({required this.repository, super.key});
  final Repository repository;
  @override
  State<CreditProductsView> createState() => _CreditProductsState();
}

class _CreditProductsState extends State<CreditProductsView> {
  String query = '';
  String status = 'Todos';
  final products = <_Product>[];
  bool loading = true;
  bool refreshing = false;
  String? error;
  bool ascending = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final initialLoad = products.isEmpty;
    setState(() {
      loading = initialLoad;
      refreshing = !initialLoad;
      error = null;
    });
    try {
      final data = await widget.repository.get('/products?limit=100&offset=0');
      if (!mounted) return;
      setState(() {
        products
          ..clear()
          ..addAll(
            (data as List).map(
              (row) => _Product.fromJson(Map<String, dynamic>.from(row as Map)),
            ),
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

  @override
  Widget build(BuildContext context) {
    final visible =
        products
            .where(
              (p) =>
                  (status == 'Todos' || p.status == status) &&
                  ('${p.name} ${p.code} ${p.type}'.toLowerCase().contains(
                    query.toLowerCase(),
                  )),
            )
            .toList()
          ..sort(
            (left, right) => ascending
                ? left.name.compareTo(right.name)
                : right.name.compareTo(left.name),
          );
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
              onPressed: () => setState(() {
                query = '';
                status = 'Todos';
              }),
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filtros'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => ascending = !ascending),
              icon: const Icon(Icons.sync),
              label: const Text('Ordenar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (refreshing) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ),
        if (loading && products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SyscrediProgressIndicator(size: 42),
                  SizedBox(height: 16),
                  Text('A carregar produtos de crédito…'),
                ],
              ),
            ),
          )
        else
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
                                onPressed: () => _toggle(p),
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
    final description = TextEditingController(text: product?.description);
    final min = TextEditingController(text: product?.min.toStringAsFixed(0));
    final max = TextEditingController(text: product?.max.toStringAsFixed(0));
    var type = product?.type ?? 'Pessoal';
    var method = product?.method ?? 'Saldo decrescente';
    var period = product?.period ?? 'Anual';
    var minTerm = '${product?.minMonths ?? 1} mês';
    var maxTerm = '${product?.maxMonths ?? 12} meses';
    var frequency = product?.frequency ?? 'Mensal';
    final saved = await showDialog<bool>(
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
                  _field(description, 'Descrição comercial', lines: 2),
                  _section('Limites e juros'),
                  _fields([
                    _field(min, 'Montante mínimo'),
                    _field(max, 'Montante máximo'),
                    _select(
                      'Tipo de crédito',
                      [
                        'Pessoal',
                        'Consumo',
                        'Empresarial',
                        'Emergência',
                        'Salário',
                        'Grupo',
                      ],
                      initial: type,
                      onChanged: (value) => type = value,
                    ),
                  ]),
                  _fields([
                    _select(
                      'Método de cálculo',
                      ['Juro flat', 'Saldo decrescente', 'Anuidade'],
                      initial: method,
                      onChanged: (value) => method = value,
                    ),
                    _select(
                      'Periodicidade da taxa',
                      ['Mensal', 'Trimestral', 'Anual'],
                      initial: period,
                      onChanged: (value) => period = value,
                    ),
                  ]),
                  _section('Prazo e prestações'),
                  _fields([
                    _select(
                      'Prazo mínimo',
                      ['1 mês', '3 meses', '6 meses'],
                      initial: minTerm,
                      onChanged: (value) => minTerm = value,
                    ),
                    _select(
                      'Prazo máximo',
                      ['6 meses', '12 meses', '24 meses'],
                      initial: maxTerm,
                      onChanged: (value) => maxTerm = value,
                    ),
                    _select(
                      'Frequência',
                      ['Semanal', 'Quinzenal', 'Mensal'],
                      initial: frequency,
                      onChanged: (value) => frequency = value,
                    ),
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
                Navigator.pop(dialog, true);
              }
            },
            child: const Text('Guardar produto'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    final minAmount = (num.tryParse(min.text.trim()) ?? 0) * 100;
    final maxAmount = (num.tryParse(max.text.trim()) ?? 0) * 100;
    final payload = <String, dynamic>{
      'name': name.text.trim(),
      'code': code.text.trim(),
      'description': description.text.trim(),
      'annualRateBps': product?.annualRateBps ?? 3000,
      'minAmountCents': minAmount.round(),
      'maxAmountCents': maxAmount.round(),
      'minMonths': _months(minTerm),
      'maxMonths': _months(maxTerm),
      'currency': product?.currency ?? 'MZN',
      'productType': _typeValue(type),
      'ratePeriod': period == 'Mensal' ? 'monthly' : 'annual',
      'interestMethod': method == 'Juro flat' ? 'flat' : 'declining_balance',
      'paymentFrequency': _frequencyValue(frequency),
      'status': product?.statusValue ?? 'active',
      'fees': product?.fees ?? <dynamic>[],
      'penalties': product?.penalties ?? <dynamic>[],
      'gracePeriodDays': product?.gracePeriodDays ?? 0,
      'eligibilityRules': product?.eligibilityRules ?? <String, dynamic>{},
    };
    if (product != null) {
      payload['version'] = product.version;
      payload['active'] = product.statusValue == 'active';
    }
    try {
      await widget.repository.write(
        product == null ? 'POST' : 'PATCH',
        product == null ? '/products' : '/products/${product.id}',
        payload,
      );
      await _load();
      if (mounted && context.mounted) _toast(context, 'Produto guardado.');
    } catch (failure) {
      if (mounted && context.mounted) _toast(context, '$failure');
    }
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
  Widget _select(
    String label,
    List<String> values, {
    String? initial,
    ValueChanged<String>? onChanged,
  }) => SizedBox(
    width: 260,
    child: DropdownButtonFormField<String>(
      initialValue: values.contains(initial) ? initial : values.first,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in values)
          DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged?.call(value);
      },
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

  Future<void> _toggle(_Product product) async {
    final next = product.statusValue == 'active' ? 'inactive' : 'active';
    try {
      await widget.repository.write('PATCH', '/products/${product.id}', {
        ...product.payload,
        'version': product.version,
        'status': next,
        'active': next == 'active',
      });
      await _load();
    } catch (failure) {
      if (mounted) _toast(context, '$failure');
    }
  }

  int _months(String value) => int.tryParse(value.split(' ').first) ?? 1;
  String _typeValue(String value) => switch (value) {
    'Empresarial' => 'business',
    'Consumo' => 'consumer',
    'Emergência' => 'emergency',
    'Grupo' => 'group',
    _ => 'individual',
  };
  String _frequencyValue(String value) => switch (value) {
    'Semanal' => 'weekly',
    'Quinzenal' => 'biweekly',
    'Trimestral' => 'quarterly',
    _ => 'monthly',
  };
}

class _Product {
  _Product.fromJson(this.raw);
  final Map<String, dynamic> raw;
  String get id => '${raw['id']}';
  String get name => '${raw['name'] ?? ''}';
  String get code => '${raw['code'] ?? ''}';
  String get description => '${raw['description'] ?? ''}';
  String get currency => '${raw['currency'] ?? 'MZN'}';
  int get annualRateBps => int.tryParse('${raw['annual_rate_bps']}') ?? 0;
  int get version => int.tryParse('${raw['version']}') ?? 1;
  int get minMonths => int.tryParse('${raw['min_months']}') ?? 1;
  int get maxMonths => int.tryParse('${raw['max_months']}') ?? 1;
  int get gracePeriodDays => int.tryParse('${raw['grace_period_days']}') ?? 0;
  double get min => (num.tryParse('${raw['min_amount_cents']}') ?? 0) / 100;
  double get max => (num.tryParse('${raw['max_amount_cents']}') ?? 0) / 100;
  String get statusValue =>
      '${raw['status'] ?? (raw['active'] == true ? 'active' : 'inactive')}';
  String get status => switch (statusValue) {
    'draft' => 'Rascunho',
    'inactive' => 'Inactivo',
    _ => 'Activo',
  };
  String get type => switch ('${raw['product_type'] ?? 'individual'}') {
    'business' => 'Empresarial',
    'consumer' => 'Consumo',
    'emergency' => 'Emergência',
    'group' || 'solidarity' => 'Grupo',
    _ => 'Pessoal',
  };
  String get rate =>
      '${(annualRateBps / 100).toStringAsFixed(2)}% ${period.toLowerCase()}';
  String get period => raw['rate_period'] == 'monthly' ? 'Mensal' : 'Anual';
  String get method =>
      raw['interest_method'] == 'flat' ? 'Juro flat' : 'Saldo decrescente';
  String get term => '$minMonths–$maxMonths meses';
  String get frequency => switch ('${raw['payment_frequency'] ?? 'monthly'}') {
    'weekly' => 'Semanal',
    'biweekly' => 'Quinzenal',
    'quarterly' => 'Trimestral',
    _ => 'Mensal',
  };
  List<dynamic> get fees =>
      List<dynamic>.from(raw['fees'] as List? ?? const []);
  List<dynamic> get penalties =>
      List<dynamic>.from(raw['penalties'] as List? ?? const []);
  Map<String, dynamic> get eligibilityRules => Map<String, dynamic>.from(
    raw['eligibility_rules'] as Map? ?? const <String, dynamic>{},
  );
  Map<String, dynamic> get payload => {
    'name': name,
    'code': code,
    'description': description,
    'annualRateBps': annualRateBps,
    'minAmountCents': (min * 100).round(),
    'maxAmountCents': (max * 100).round(),
    'minMonths': minMonths,
    'maxMonths': maxMonths,
    'currency': currency,
    'productType': '${raw['product_type'] ?? 'individual'}',
    'ratePeriod': '${raw['rate_period'] ?? 'annual'}',
    'interestMethod': '${raw['interest_method'] ?? 'declining_balance'}',
    'paymentFrequency': '${raw['payment_frequency'] ?? 'monthly'}',
    'fees': fees,
    'penalties': penalties,
    'gracePeriodDays': gracePeriodDays,
    'eligibilityRules': eligibilityRules,
  };
}
