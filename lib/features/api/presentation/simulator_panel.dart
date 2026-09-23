import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_design.dart';
import '../domain/money.dart';

class SimulatorPanel extends StatefulWidget {
  const SimulatorPanel({super.key});

  @override
  State<SimulatorPanel> createState() => _SimulatorPanelState();
}

class _SimulatorPanelState extends State<SimulatorPanel> {
  final principal = TextEditingController(text: '10000');
  final term = TextEditingController(text: '12');
  final annualRate = TextEditingController(text: '30');
  final originationFee = TextEditingController(text: '0');
  final insurance = TextEditingController(text: '0');
  final client = TextEditingController();
  final phone = TextEditingController();
  DateTime start = DateTime.now();
  String creditType = 'Parcelado';
  String frequency = 'Mensal';
  String interestType = 'Amortização francesa';

  bool get isMonthlyCredit => creditType == 'Crédito mensal';

  @override
  void dispose() {
    for (final controller in [
      principal,
      term,
      annualRate,
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
    final amount = number(principal).clamp(0, double.infinity).toDouble();
    if (isMonthlyCredit) {
      final days = number(term).round().clamp(1, 30);
      final rate = days <= 14 ? 20.0 : 30.0;
      final interest = amount * rate / 100;
      final fee = amount * number(originationFee).clamp(0, 100) / 100;
      final insuranceValue = amount * number(insurance).clamp(0, 100) / 100;
      final total = amount + interest + fee + insuranceValue;
      return _Simulation(
        amount: amount,
        periods: 1,
        payment: total,
        interest: interest,
        fees: fee + insuranceValue,
        total: total,
        rows: [
          _Installment(
            1,
            start.add(Duration(days: days)),
            total,
            amount,
            interest,
            0,
          ),
        ],
      );
    }
    final months = number(term).round().clamp(1, 120);
    final annual = number(annualRate).clamp(0, 1000).toDouble();
    final feeRate = number(originationFee).clamp(0, 100).toDouble();
    final insuranceRate = number(insurance).clamp(0, 100).toDouble();
    final periods = frequency == 'Semanal'
        ? months * 4
        : frequency == 'Quinzenal'
        ? months * 2
        : months;
    final periodRate =
        annual /
        100 /
        (frequency == 'Semanal'
            ? 52
            : frequency == 'Quinzenal'
            ? 26
            : 12);
    final payment = interestType == 'Juros simples'
        ? (amount * (1 + periodRate * periods)) / periods
        : periodRate == 0
        ? amount / periods
        : amount * periodRate / (1 - _pow(1 + periodRate, -periods));
    var balance = amount;
    final rows = <_Installment>[];
    for (var index = 1; index <= periods; index++) {
      final interest = interestType == 'Juros simples'
          ? amount * periodRate
          : balance * periodRate;
      final principalPart = index == periods
          ? balance
          : (payment - interest).clamp(0, balance).toDouble();
      balance = (balance - principalPart).clamp(0, double.infinity).toDouble();
      rows.add(
        _Installment(
          index,
          _dueDate(index),
          payment,
          principalPart,
          interest,
          balance,
        ),
      );
    }
    final fee = amount * feeRate / 100;
    final insuranceValue = amount * insuranceRate / 100;
    final installments = rows.fold<double>(0, (sum, row) => sum + row.payment);
    return _Simulation(
      amount: amount,
      periods: periods,
      payment: payment,
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

  DateTime _dueDate(int index) => frequency == 'Semanal'
      ? start.add(Duration(days: index * 7))
      : frequency == 'Quinzenal'
      ? start.add(Duration(days: index * 14))
      : DateTime(start.year, start.month + index, start.day);

  void _reset() {
    principal.text = '10000';
    term.text = '12';
    annualRate.text = '30';
    originationFee.text = '0';
    insurance.text = '0';
    client.clear();
    phone.clear();
    creditType = 'Parcelado';
    frequency = 'Mensal';
    interestType = 'Amortização francesa';
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
                    height: 410,
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
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: FluentTokens.space8,
              crossAxisSpacing: FluentTokens.space8,
              childAspectRatio: columns == 3 ? 3.6 : 3.35,
              children: [
                SizedBox(
                  height: 52,
                  child: DropdownButtonFormField<String>(
                    initialValue: creditType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de crédito',
                      isDense: true,
                      constraints: BoxConstraints.tightFor(height: 52),
                    ),
                    items: ['Parcelado', 'Crédito mensal']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        creditType = value;
                        if (isMonthlyCredit) {
                          term.text = '30';
                          annualRate.text = '30';
                          frequency = 'Mensal';
                          interestType = 'Juros simples';
                        } else {
                          term.text = '12';
                          annualRate.text = '30';
                        }
                      });
                    },
                  ),
                ),
                _moneyField('Capital', principal, 'Montante em MT'),
                _numberField(
                  'Prazo',
                  term,
                  isMonthlyCredit ? 'dias' : 'meses',
                  min: 1,
                  max: isMonthlyCredit ? 30 : 120,
                  onChanged: isMonthlyCredit
                      ? (_) {
                          final days = number(term).round();
                          annualRate.text = days <= 14 ? '20' : '30';
                          setState(() {});
                        }
                      : null,
                ),
                _numberField(
                  isMonthlyCredit ? 'Taxa do período' : 'Taxa anual',
                  annualRate,
                  '%',
                  min: 0,
                  max: 1000,
                  readOnly: isMonthlyCredit,
                  hint: isMonthlyCredit
                      ? '20% até 14 dias; 30% até 30 dias'
                      : null,
                ),
                _numberField(
                  'Taxa de abertura',
                  originationFee,
                  '%',
                  min: 0,
                  max: 100,
                ),
                _numberField('Seguro', insurance, '%', min: 0, max: 100),
                if (!isMonthlyCredit)
                  SizedBox(
                    height: 52,
                    child: DropdownButtonFormField<String>(
                      initialValue: frequency,
                      isExpanded: true,
                      iconSize: FluentTokens.iconMedium,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Frequência',
                        isDense: true,
                        constraints: BoxConstraints.tightFor(height: 52),
                      ),
                      items: ['Mensal', 'Quinzenal', 'Semanal']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(
                                value,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => frequency = value ?? frequency),
                    ),
                  ),
                if (!isMonthlyCredit)
                  DropdownButtonFormField<String>(
                    initialValue: interestType,
                    isExpanded: true,
                    iconSize: FluentTokens.iconMedium,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Método de juros',
                      isDense: true,
                      constraints: BoxConstraints.tightFor(height: 52),
                    ),
                    items: ['Amortização francesa', 'Juros simples']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => interestType = value ?? interestType),
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
