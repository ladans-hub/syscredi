import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_design.dart';
import '../domain/money.dart';
import '../domain/repository.dart';

class SimulatorPanel extends StatefulWidget {
  const SimulatorPanel({required this.repository, super.key});

  final Repository repository;

  @override
  State<SimulatorPanel> createState() => _SimulatorPanelState();
}

class _SimulatorPanelState extends State<SimulatorPanel> {
  final principal = TextEditingController(text: '10000');
  final term = TextEditingController(text: '12');
  final annualRate = TextEditingController(text: '30');
  final shortTermRate = TextEditingController(text: '20.00');
  final originationFee = TextEditingController(text: '0');
  final insurance = TextEditingController(text: '0');
  final client = TextEditingController();
  final phone = TextEditingController();
  DateTime start = DateTime.now();
  final products = <_SimulationProduct>[];
  String? selectedProductId;
  bool shortTerm = false;
  bool loadingProducts = true;
  String? productError;

  _SimulationProduct? get selectedProduct {
    for (final product in products) {
      if (product.id == selectedProductId) return product;
    }
    return products.isEmpty ? null : products.first;
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final rows = await widget.repository.get('/products?limit=100&offset=0');
      final loaded = (rows as List)
          .map(
            (row) => _SimulationProduct.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .where((product) => product.active)
          .toList();
      if (!mounted) return;
      setState(() {
        products
          ..clear()
          ..addAll(loaded);
        selectedProductId = _defaultProduct(loaded)?.id;
        loadingProducts = false;
        productError = null;
        _applyProduct();
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        loadingProducts = false;
        productError = '$failure';
      });
    }
  }

  _SimulationProduct? _defaultProduct(List<_SimulationProduct> values) {
    if (values.isEmpty) return null;
    for (final product in values) {
      final name = product.name.toLowerCase();
      final code = product.code.toLowerCase();
      if (name == 'crédito rápido' ||
          name == 'credito rapido' ||
          code.contains('rapido') ||
          code.contains('rápido')) {
        return product;
      }
    }
    return values.first;
  }

  void _applyProduct() {
    final product = selectedProduct;
    if (product == null) return;
    principal.text = product.defaultAmount.toStringAsFixed(0);
    term.text = product.minMonths.toString();
    shortTerm = false;
    annualRate.text = product.displayRate.toStringAsFixed(2);
    originationFee.text = product.originationFeeRate.toStringAsFixed(2);
    insurance.text = product.insuranceRate.toStringAsFixed(2);
  }

  @override
  void dispose() {
    for (final controller in [
      principal,
      term,
      annualRate,
      shortTermRate,
      originationFee,
      insurance,
      client,
      phone,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '.')) ?? 0;

  _Simulation get simulation {
    final product = selectedProduct;
    final amount = number(principal).clamp(0, double.infinity).toDouble();
    if (product == null || amount == 0) return _Simulation.empty(amount);
    if (shortTerm && product.isQuickCredit) {
      final days = number(term).round().clamp(1, 14);
      final interest = amount * .20;
      final fee = amount * product.originationFeeRate / 100;
      final insuranceValue = amount * product.insuranceRate / 100;
      return _Simulation(
        amount: amount,
        periods: 1,
        payment: amount + interest,
        interest: interest,
        fees: fee + insuranceValue,
        total: amount + interest + fee + insuranceValue,
        rows: [
          _Installment(
            1,
            start.add(Duration(days: days)),
            amount + interest,
            amount,
            interest,
            0,
          ),
        ],
      );
    }
    final months = number(
      term,
    ).round().clamp(product.minMonths, product.maxMonths);
    final periods = product.periodsForMonths(months);
    final periodRate = product.periodRate;
    final fee = amount * product.originationFeeRate / 100;
    final insuranceValue = amount * product.insuranceRate / 100;
    var balance = amount;
    final rows = <_Installment>[];
    if (product.interestMethod == 'flat') {
      final interestPerPeriod = amount * periodRate;
      final principalPerPeriod = periods == 0 ? 0.0 : amount / periods;
      for (var index = 1; index <= periods; index++) {
        final principalPart = index == periods ? balance : principalPerPeriod;
        balance = (balance - principalPart)
            .clamp(0, double.infinity)
            .toDouble();
        rows.add(
          _Installment(
            index,
            product.dueDate(start, index),
            principalPart + interestPerPeriod,
            principalPart,
            interestPerPeriod,
            balance,
          ),
        );
      }
    } else {
      final payment = periodRate == 0
          ? amount / periods
          : amount * periodRate / (1 - _pow(1 + periodRate, -periods));
      for (var index = 1; index <= periods; index++) {
        final interest = balance * periodRate;
        final principalPart = index == periods
            ? balance
            : (payment - interest).clamp(0, balance).toDouble();
        balance = (balance - principalPart)
            .clamp(0, double.infinity)
            .toDouble();
        rows.add(
          _Installment(
            index,
            product.dueDate(start, index),
            principalPart + interest,
            principalPart,
            interest,
            balance,
          ),
        );
      }
    }
    final installments = rows.fold<double>(0, (sum, row) => sum + row.payment);
    return _Simulation(
      amount: amount,
      periods: periods,
      payment: rows.isEmpty ? 0 : rows.first.payment,
      interest: (installments - amount).clamp(0, double.infinity).toDouble(),
      fees: fee + insuranceValue,
      total: installments + fee + insuranceValue,
      rows: rows,
    );
  }

  double _pow(double value, int exponent) => exponent == 0
      ? 1
      : (exponent < 0
            ? 1 / _pow(value, -exponent)
            : value * _pow(value, exponent - 1));

  void _reset() {
    selectedProductId = _defaultProduct(products)?.id;
    _applyProduct();
    client.clear();
    phone.clear();
    setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => start = picked);
  }

  @override
  Widget build(BuildContext context) {
    final result = simulation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulador de microcrédito',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: FluentTokens.space4),
                  Text(
                    'Configure condições, compare custos e consulte o plano de pagamentos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            FluentActionButton(
              label: 'Limpar',
              icon: FluentSystemIcons.refresh,
              kind: FluentActionKind.subtle,
              onPressed: _reset,
            ),
          ],
        ),
        const SizedBox(height: FluentTokens.space20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            final form = _formCard();
            final summary = _summaryCard(result);
            return compact
                ? Column(
                    children: [
                      form,
                      const SizedBox(height: FluentTokens.space16),
                      summary,
                    ],
                  )
                : SizedBox(
                    height: selectedProduct?.isQuickCredit == true ? 480 : 420,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 3, child: form),
                        const SizedBox(width: FluentTokens.space16),
                        Expanded(flex: 2, child: summary),
                      ],
                    ),
                  );
          },
        ),
        const SizedBox(height: FluentTokens.space16),
        _scheduleCard(result),
      ],
    );
  }

  Widget _formCard() => FluentSurface(
    padding: const EdgeInsets.all(FluentTokens.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          FluentSystemIcons.settings,
          'Parâmetros da simulação',
          'Ajuste os valores para recalcular em tempo real.',
        ),
        const SizedBox(height: FluentTokens.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 580 ? 3 : 2;
            final fields = <Widget>[
              SizedBox(
                height: 52,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selectedProductId),
                  initialValue: selectedProductId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Produto de crédito',
                    isDense: true,
                    constraints: const BoxConstraints.tightFor(height: 52),
                    errorText: productError,
                  ),
                  items: [
                    for (final product in products)
                      DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: loadingProducts
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            selectedProductId = value;
                            _applyProduct();
                          });
                        },
                ),
              ),
              _moneyField('Capital', principal, 'Montante em MT'),
              _numberField(
                'Prazo',
                term,
                shortTerm ? 'dias' : 'meses',
                min: shortTerm
                    ? 1
                    : (selectedProduct?.minMonths ?? 1).toDouble(),
                max: shortTerm
                    ? 14
                    : (selectedProduct?.maxMonths ?? 360).toDouble(),
                hint: shortTerm
                    ? '1–14 dias'
                    : selectedProduct == null
                    ? null
                    : '${selectedProduct!.minMonths}–${selectedProduct!.maxMonths} meses',
              ),
              _numberField(
                shortTerm
                    ? 'Taxa do período'
                    : selectedProduct?.ratePeriod == 'monthly'
                    ? 'Taxa mensal'
                    : 'Taxa anual',
                shortTerm ? shortTermRate : annualRate,
                '%',
                min: 0,
                max: 1000,
                readOnly: true,
              ),
              _numberField(
                'Taxa de abertura',
                originationFee,
                '%',
                min: 0,
                max: 100,
                readOnly: true,
              ),
              _numberField(
                'Seguro',
                insurance,
                '%',
                min: 0,
                max: 100,
                readOnly: true,
              ),
              TextFormField(
                readOnly: true,
                initialValue: selectedProduct?.frequencyLabel ?? '—',
                key: ValueKey('frequency-$selectedProductId'),
                decoration: const InputDecoration(
                  labelText: 'Frequência',
                  isDense: true,
                  constraints: BoxConstraints.tightFor(height: 52),
                ),
              ),
              TextFormField(
                readOnly: true,
                initialValue: selectedProduct?.methodLabel ?? '—',
                key: ValueKey('method-$selectedProductId'),
                decoration: const InputDecoration(
                  labelText: 'Método de juros',
                  isDense: true,
                  constraints: BoxConstraints.tightFor(height: 52),
                ),
              ),
              TextFormField(
                readOnly: true,
                initialValue: _dateLabel(start),
                decoration: const InputDecoration(
                  labelText: 'Data da operação',
                  isDense: true,
                  constraints: BoxConstraints.tightFor(height: 52),
                  suffixIcon: Icon(
                    FluentSystemIcons.calendar,
                    size: FluentTokens.iconSmall,
                  ),
                ),
                style: const TextStyle(fontSize: 13),
                onTap: _pickDate,
              ),
              _textField(
                'Cliente (opcional)',
                client,
                FluentSystemIcons.person,
              ),
              _textField(
                'Telefone (opcional)',
                phone,
                FluentSystemIcons.person,
              ),
            ];
            return Column(
              children: [
                if (selectedProduct?.isQuickCredit ?? false) ...[
                  _termModeSelector(),
                  const SizedBox(height: FluentTokens.space8),
                ],
                GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: FluentTokens.space8,
                  crossAxisSpacing: FluentTokens.space8,
                  childAspectRatio: columns == 3 ? 3.6 : 3.35,
                  children: fields,
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _summaryCard(_Simulation result) => FluentSurface(
    padding: const EdgeInsets.all(FluentTokens.space20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          FluentSystemIcons.analytics,
          'Resumo da simulação',
          'Valores calculados para a proposta actual.',
        ),
        const SizedBox(height: FluentTokens.space16),
        _metric(
          'Prestação estimada',
          money((result.payment * 100).round()),
          primary: true,
        ),
        const Divider(height: 24),
        _metric('Capital financiado', money((result.amount * 100).round())),
        _metric('Juros totais', money((result.interest * 100).round())),
        _metric('Taxas e seguro', money((result.fees * 100).round())),
        _metric(
          'Custo total',
          money((result.total * 100).round()),
          primary: true,
        ),
        const SizedBox(height: FluentTokens.space16),
        Container(
          padding: const EdgeInsets.all(FluentTokens.space12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(FluentTokens.radius8),
          ),
          child: Row(
            children: [
              Icon(
                FluentSystemIcons.check,
                size: FluentTokens.iconMedium,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${result.periods} prestações previstas',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _scheduleCard(_Simulation result) => FluentSurface(
    padding: const EdgeInsets.all(FluentTokens.space20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          FluentSystemIcons.calendar,
          'Plano de pagamentos',
          'Calendário detalhado da simulação.',
        ),
        const SizedBox(height: FluentTokens.space12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Vencimento')),
              DataColumn(label: Text('Prestação')),
              DataColumn(label: Text('Capital')),
              DataColumn(label: Text('Juros')),
              DataColumn(label: Text('Saldo')),
            ],
            rows: result.rows
                .map(
                  (row) => DataRow(
                    cells: [
                      DataCell(Text('${row.number}')),
                      DataCell(Text(_dateLabel(row.date))),
                      DataCell(Text(money((row.payment * 100).round()))),
                      DataCell(Text(money((row.principal * 100).round()))),
                      DataCell(Text(money((row.interest * 100).round()))),
                      DataCell(Text(money((row.balance * 100).round()))),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(IconData icon, String title, String subtitle) => Row(
    children: [
      Icon(
        icon,
        size: FluentTokens.iconMedium,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );

  Widget _termModeSelector() {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Unidade do prazo',
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: .62),
          borderRadius: BorderRadius.circular(FluentTokens.radius8),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: _termModeOption(
                selected: !shortTerm,
                icon: FluentSystemIcons.calendar,
                title: 'Mensal',
                subtitle: '30% ao mês',
                onTap: () => _setTermMode(false),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: _termModeOption(
                selected: shortTerm,
                icon: FluentSystemIcons.pending,
                title: 'Curto prazo',
                subtitle: 'Até 14 dias · 20%',
                onTap: () => _setTermMode(true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _termModeOption({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(FluentTokens.radius6),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 167),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(FluentTokens.radius6),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: .42)
                  : Colors.transparent,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.05,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1,
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(FluentSystemIcons.check, size: 14, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _setTermMode(bool value) {
    if (shortTerm == value) return;
    setState(() {
      shortTerm = value;
      term.text = value ? '14' : selectedProduct!.minMonths.toString();
    });
  }

  Widget _metric(String label, String value, {bool primary = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: primary ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    ),
  );

  Widget _moneyField(
    String label,
    TextEditingController controller,
    String hint,
  ) => _numberField(label, controller, 'MT', hint: hint, decimals: true);

  Widget _numberField(
    String label,
    TextEditingController controller,
    String suffix, {
    double min = 0,
    double max = 100000000,
    String? hint,
    bool decimals = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
  }) => SizedBox(
    height: 52,
    child: TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 13),
      keyboardType: TextInputType.numberWithOptions(decimal: decimals),
      onChanged: onChanged ?? (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        isDense: true,
        constraints: const BoxConstraints.tightFor(height: 52),
      ),
      validator: (value) {
        final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
        return parsed == null || parsed < min || parsed > max
            ? 'Valor inválido'
            : null;
      },
    ),
  );

  Widget _textField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) => TextFormField(
    controller: controller,
    style: const TextStyle(fontSize: 13),
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, size: FluentTokens.iconSmall),
      constraints: const BoxConstraints.tightFor(height: 52),
    ),
  );

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _Simulation {
  const _Simulation({
    required this.amount,
    required this.periods,
    required this.payment,
    required this.interest,
    required this.fees,
    required this.total,
    required this.rows,
  });
  final double amount, payment, interest, fees, total;
  final int periods;
  final List<_Installment> rows;

  factory _Simulation.empty(double amount) => _Simulation(
    amount: amount,
    periods: 0,
    payment: 0,
    interest: 0,
    fees: 0,
    total: amount,
    rows: const [],
  );
}

class _Installment {
  const _Installment(
    this.number,
    this.date,
    this.payment,
    this.principal,
    this.interest,
    this.balance,
  );
  final int number;
  final DateTime date;
  final double payment, principal, interest, balance;
}

class _SimulationProduct {
  const _SimulationProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.active,
    required this.annualRateBps,
    required this.ratePeriod,
    required this.interestMethod,
    required this.paymentFrequency,
    required this.minAmount,
    required this.maxAmount,
    required this.minMonths,
    required this.maxMonths,
    required this.originationFeeRate,
    required this.insuranceRate,
  });

  factory _SimulationProduct.fromJson(Map<String, dynamic> row) {
    final fees = List<Map<String, dynamic>>.from(
      (row['fees'] as List? ?? const []).map(
        (fee) => Map<String, dynamic>.from(fee as Map),
      ),
    );
    double feeRate(Iterable<String> terms) {
      for (final fee in fees) {
        final name = '${fee['name'] ?? fee['type'] ?? ''}'.toLowerCase();
        if (terms.any(name.contains)) {
          final value =
              num.tryParse(
                '${fee['percentage'] ?? fee['rate_percent'] ?? fee['rate'] ?? 0}',
              ) ??
              0;
          return value.toDouble();
        }
      }
      return 0;
    }

    return _SimulationProduct(
      id: '${row['id'] ?? ''}',
      name: '${row['name'] ?? 'Produto'}',
      code: '${row['code'] ?? ''}',
      active:
          row['active'] != false &&
          '${row['status'] ?? 'active'}' != 'inactive',
      annualRateBps: int.tryParse('${row['annual_rate_bps'] ?? 0}') ?? 0,
      ratePeriod: '${row['rate_period'] ?? 'annual'}',
      interestMethod: '${row['interest_method'] ?? 'declining_balance'}',
      paymentFrequency: '${row['payment_frequency'] ?? 'monthly'}',
      minAmount: (num.tryParse('${row['min_amount_cents'] ?? 0}') ?? 0) / 100,
      maxAmount: (num.tryParse('${row['max_amount_cents'] ?? 0}') ?? 0) / 100,
      minMonths: int.tryParse('${row['min_months'] ?? 1}') ?? 1,
      maxMonths: int.tryParse('${row['max_months'] ?? 1}') ?? 1,
      originationFeeRate: feeRate(const ['abertura', 'origination', 'admin']),
      insuranceRate: feeRate(const ['seguro', 'insurance']),
    );
  }

  final String id, name, code, ratePeriod, interestMethod, paymentFrequency;
  final bool active;
  final int annualRateBps, minMonths, maxMonths;
  final double minAmount, maxAmount, originationFeeRate, insuranceRate;

  double get defaultAmount {
    if (minAmount > 0) return minAmount;
    if (maxAmount > 0) return maxAmount.clamp(1, 10000).toDouble();
    return 10000;
  }

  double get displayRate => annualRateBps / 100;

  bool get isQuickCredit {
    final normalizedName = name.toLowerCase();
    final normalizedCode = code.toLowerCase();
    return normalizedName.contains('crédito rápido') ||
        normalizedName.contains('credito rapido') ||
        normalizedCode.contains('rapido') ||
        normalizedCode.contains('rápido');
  }

  int periodsForMonths(int months) => switch (paymentFrequency) {
    'weekly' => (months * 52 / 12).round().clamp(1, 10000),
    'biweekly' => (months * 26 / 12).round().clamp(1, 10000),
    'quarterly' => (months / 3).ceil().clamp(1, 10000),
    _ => months.clamp(1, 10000),
  };

  double get periodRate {
    final configured = annualRateBps / 10000;
    if (ratePeriod == 'monthly') {
      return switch (paymentFrequency) {
        'weekly' => configured * 12 / 52,
        'biweekly' => configured * 12 / 26,
        'quarterly' => configured * 3,
        _ => configured,
      };
    }
    return switch (paymentFrequency) {
      'weekly' => configured / 52,
      'biweekly' => configured / 26,
      'quarterly' => configured / 4,
      _ => configured / 12,
    };
  }

  DateTime dueDate(DateTime start, int index) => switch (paymentFrequency) {
    'weekly' => start.add(Duration(days: index * 7)),
    'biweekly' => start.add(Duration(days: index * 14)),
    'quarterly' => DateTime(start.year, start.month + index * 3, start.day),
    _ => DateTime(start.year, start.month + index, start.day),
  };

  String get frequencyLabel => switch (paymentFrequency) {
    'weekly' => 'Semanal',
    'biweekly' => 'Quinzenal',
    'quarterly' => 'Trimestral',
    _ => 'Mensal',
  };

  String get methodLabel =>
      interestMethod == 'flat' ? 'Juro flat' : 'Saldo decrescente';
}
