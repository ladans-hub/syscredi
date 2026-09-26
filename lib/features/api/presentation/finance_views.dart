import 'package:flutter/material.dart' hide Icons;

import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../domain/money.dart';
import '../domain/repository.dart';
import 'form.dart';

class FinanceView extends StatefulWidget {
  const FinanceView({required this.area, required this.repository, super.key});

  final String area;
  final Repository repository;

  @override
  State<FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<FinanceView> {
  final searchController = TextEditingController();
  List<Json> rows = [];
  List<Json> accounts = [];
  bool loading = true;
  bool refreshing = false;
  bool writing = false;
  String query = '';
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant FinanceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.area != widget.area) {
      rows = [];
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

  _FinanceSpec get spec => _specs[widget.area] ?? _specs['Saldos']!;

  Future<void> _load() async {
    if (refreshing) return;
    setState(() {
      loading = rows.isEmpty;
      refreshing = rows.isNotEmpty;
      error = null;
    });
    try {
      final loadedAccounts = await widget.repository
          .get('/accounts?limit=100&offset=0')
          .catchError((_) => <dynamic>[]);
      final loaded = await _loadRows();
      if (!mounted) return;
      setState(() {
        accounts = (loadedAccounts as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        rows = loaded;
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

  Future<List<Json>> _getList(String path) async =>
      (await widget.repository.get(path) as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

  Future<List<Json>> _loadRows() async {
    switch (widget.area) {
      case 'Saldos':
      case 'Ativos':
        return _getList('/accounts?limit=100&offset=0');
      case 'Estornos':
      case 'Reembolsos':
        return _getList('/payments?limit=100&offset=0');
      case 'Receitas':
      case 'Despesas':
        return _getList('/cash-entries?limit=100&offset=0');
      case 'Desembolsos':
        return _getList('/loans?limit=100&offset=0');
      case 'Prestações Vencidas':
        final loans = await _getList('/loans?limit=100&offset=0');
        final overdue = <Json>[];
        for (final loan in loans) {
          final loanId = '${loan['id'] ?? ''}';
          if (loanId.isEmpty) continue;
          final installments = await _getList('/loans/$loanId/installments');
          for (final installment in installments) {
            final due = DateTime.tryParse('${installment['due_date']}');
            final remaining = _cents(installment['remaining_cents']) > 0
                ? _cents(installment['remaining_cents'])
                : _cents(installment['principal_cents']) +
                      _cents(installment['interest_cents']) -
                      _cents(installment['paid_cents']);
            if (due == null ||
                !due.isBefore(DateTime.now()) ||
                remaining <= 0) {
              continue;
            }
            overdue.add({
              ...loan,
              'installment_number': installment['number'],
              'due_date': installment['due_date'],
              'remaining_cents': remaining,
              'days_past_due': DateTime.now().difference(due).inDays,
            });
          }
        }
        return overdue;
      default:
        return [];
    }
  }

  static int _cents(dynamic value) =>
      (num.tryParse('${value ?? 0}') ?? 0).round();

  List<Json> get shown {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return rows;
    return rows
        .where((row) => row.values.join(' ').toLowerCase().contains(normalized))
        .toList();
  }

  int get totalCents => rows.fold(0, (sum, row) {
    final key = switch (widget.area) {
      'Saldos' || 'Ativos' => 'balance_cents',
      'Receitas' || 'Despesas' => 'amount_cents',
      'Desembolsos' => 'principal_cents',
      'Estornos' || 'Reembolsos' => 'amount_cents',
      'Prestações Vencidas' => 'remaining_cents',
      _ => 'amount_cents',
    };
    final value = _cents(row[key]);
    if (widget.area == 'Receitas' && value < 0) return sum;
    if (widget.area == 'Despesas' && value > 0) return sum;
    return sum + value.abs();
  });

  List<Json> get areaRows {
    if (widget.area == 'Receitas') {
      return shown.where((row) => _cents(row['amount_cents']) > 0).toList();
    }
    if (widget.area == 'Despesas') {
      return shown.where((row) => _cents(row['amount_cents']) < 0).toList();
    }
    return shown;
  }

  Future<void> _primaryAction() async {
    switch (widget.area) {
      case 'Saldos':
        await _createAccount();
      case 'Receitas':
        await _cashMovement('deposit');
      case 'Despesas':
        await _cashMovement('withdrawal');
      case 'Reembolsos':
        await _registerPayment();
      default:
        await showFeedbackDialog(
          context,
          title: spec.title,
          message:
              'Esta área é alimentada automaticamente pelas operações confirmadas.',
        );
    }
  }

  Future<void> _createAccount() async {
    final body = await form(context, widget.repository, 'Nova conta', const [
      Field('name', 'Nome da conta'),
      Field(
        'currency',
        'Moeda',
        options: {'MZN': 'MZN', 'USD': 'USD', 'EUR': 'EUR', 'ZAR': 'ZAR'},
        initial: 'MZN',
      ),
      Field(
        'openingBalanceCents',
        'Saldo inicial',
        kind: 'money',
        initial: '0',
      ),
    ]);
    if (body != null) await _write('POST', '/accounts', body, 'Conta criada');
  }

  Future<void> _cashMovement(String type) async {
    final body = await form(
      context,
      widget.repository,
      type == 'deposit' ? 'Nova receita' : 'Nova despesa',
      [
        const Field('accountId', 'Conta', resource: 'payment-accounts'),
        Field(
          'type',
          'Tipo',
          options: {type: type == 'deposit' ? 'Entrada' : 'Saída'},
          initial: type,
        ),
        const Field('amountCents', 'Valor', kind: 'money'),
        if (type == 'withdrawal')
          const Field('description', 'Descrição da despesa'),
      ],
    );
    if (body != null) {
      await _write('POST', '/cash-entries', body, 'Movimento registado');
    }
  }

  Future<void> _registerPayment() async {
    final body = await form(
      context,
      widget.repository,
      'Registar pagamento',
      const [
        Field('loanId', 'Crédito', resource: 'loans'),
        Field('accountId', 'Conta', resource: 'payment-accounts'),
        Field('amountCents', 'Valor', kind: 'money'),
        Field(
          'method',
          'Forma de pagamento',
          options: {
            'cash': 'Dinheiro',
            'bank_transfer': 'Transferência bancária',
            'mpesa': 'M-Pesa',
            'emola': 'e-Mola',
            'mkesh': 'mKesh',
            'bim': 'BIM',
            'bci': 'BCI',
          },
          initial: 'cash',
        ),
        Field('externalReference', 'Referência externa', optional: true),
      ],
    );
    if (body != null) {
      await _write('POST', '/payments', body, 'Pagamento registado');
    }
  }

  Future<void> _reverse(Json row) async {
    final paymentId = '${row['id'] ?? ''}';
    if (paymentId.isEmpty) return;
    final body = await form(
      context,
      widget.repository,
      'Estornar pagamento',
      const [Field('reason', 'Motivo do estorno')],
    );
    if (body != null) {
      await _write(
        'POST',
        '/payments/$paymentId/reverse',
        body,
        'Estorno submetido',
      );
    }
  }

  Future<void> _write(
    String method,
    String path,
    Json body,
    String successTitle,
  ) async {
    if (writing) return;
    setState(() => writing = true);
    try {
      await widget.repository.write(method, path, body);
      await _load();
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: successTitle,
          message: 'A operação foi confirmada e os dados foram actualizados.',
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

  String _accountName(dynamic id) {
    final value = '$id';
    for (final account in accounts) {
      if ('${account['id']}' == value) return '${account['name']}';
    }
    return value.isEmpty ? '—' : value;
  }

  String _cell(Json row, String key) => switch (key) {
    'account' => _accountName(row['account_id'] ?? row['id']),
    'balance' => money(row['balance_cents']),
    'amount' => money(_cents(row['amount_cents']).abs()),
    'principal' => money(row['principal_cents']),
    'remaining' => money(row['remaining_cents']),
    'client' => '${row['client_name'] ?? row['client_id'] ?? '—'}',
    'loan' =>
      '${row['number'] ?? row['contract_number'] ?? row['loan_id'] ?? row['id'] ?? '—'}',
    'method' => _method('${row['method'] ?? ''}'),
    'source' => '${row['description'] ?? row['source'] ?? '—'}',
    'status' => _status(
      '${row['status'] ?? (row['active'] == true ? 'active' : '')}',
    ),
    'date' => _date(row['created_at'] ?? row['due_date']),
    'days' => '${row['days_past_due'] ?? 0}',
    'installment' => '${row['installment_number'] ?? '—'}',
    'currency' => '${row['currency'] ?? 'MZN'}',
    _ => '${row[key] ?? '—'}',
  };

  String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _method(String value) =>
      const {
        'cash': 'Dinheiro',
        'bank_transfer': 'Transferência',
        'mpesa': 'M-Pesa',
        'emola': 'e-Mola',
        'mkesh': 'mKesh',
        'bim': 'BIM',
        'bci': 'BCI',
      }[value] ??
      (value.isEmpty ? '—' : value);

  String _status(String value) =>
      const {
        'active': 'Activo',
        'settled': 'Liquidado',
        'disbursed': 'Desembolsado',
        'reversed': 'Estornado',
      }[value] ??
      (value.isEmpty ? 'Confirmado' : value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            if (spec.action != null) ...[
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: writing ? null : _primaryAction,
                icon: const Icon(Icons.add),
                label: Text(spec.action!),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('Total', money(totalCents)),
            _metric('Registos', '${areaRows.length}'),
            _metric(
              'Contas activas',
              '${accounts.where((row) => row['active'] == true).length}',
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Pesquisar em ${spec.title.toLowerCase()}',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      searchController.clear();
                      setState(() => query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        if (refreshing || writing) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text('Não foi possível carregar ${spec.title.toLowerCase()}.'),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _load,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (areaRows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Nenhum registo disponível em ${spec.title.toLowerCase()}.',
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
                  if (widget.area == 'Estornos')
                    const DataColumn(label: Text('ACÇÕES')),
                ],
                rows: [
                  for (final row in areaRows)
                    DataRow(
                      cells: [
                        for (final column in spec.columns)
                          DataCell(Text(_cell(row, column.$2))),
                        if (widget.area == 'Estornos')
                          DataCell(
                            IconButton(
                              tooltip: 'Estornar pagamento',
                              onPressed: writing ? null : () => _reverse(row),
                              icon: const Icon(Icons.refresh),
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

class _FinanceSpec {
  const _FinanceSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.columns,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<(String, String)> columns;
  final String? action;
}

const _specs = <String, _FinanceSpec>{
  'Saldos': _FinanceSpec(
    title: 'Saldos',
    subtitle: 'Contas financeiras e disponibilidades actualizadas.',
    icon: Icons.account_balance_wallet_outlined,
    action: 'Nova conta',
    columns: [
      ('Conta', 'account'),
      ('Moeda', 'currency'),
      ('Saldo', 'balance'),
      ('Estado', 'status'),
    ],
  ),
  'Estornos': _FinanceSpec(
    title: 'Estornos',
    subtitle: 'Pagamentos confirmados disponíveis para reversão auditada.',
    icon: Icons.refresh,
    columns: [
      ('Data', 'date'),
      ('Crédito', 'loan'),
      ('Conta', 'account'),
      ('Método', 'method'),
      ('Valor', 'amount'),
    ],
  ),
  'Receitas': _FinanceSpec(
    title: 'Receitas',
    subtitle: 'Entradas financeiras confirmadas nas contas da instituição.',
    icon: Icons.trending_up_rounded,
    action: 'Nova receita',
    columns: [
      ('Data', 'date'),
      ('Conta', 'account'),
      ('Origem', 'source'),
      ('Valor', 'amount'),
    ],
  ),
  'Despesas': _FinanceSpec(
    title: 'Despesas',
    subtitle: 'Saídas financeiras e custos operacionais confirmados.',
    icon: Icons.south,
    action: 'Nova despesa',
    columns: [
      ('Data', 'date'),
      ('Conta', 'account'),
      ('Descrição', 'source'),
      ('Valor', 'amount'),
    ],
  ),
  'Desembolsos': _FinanceSpec(
    title: 'Desembolsos',
    subtitle: 'Créditos libertados e respectivos saldos em carteira.',
    icon: Icons.payments_outlined,
    columns: [
      ('Cliente', 'client'),
      ('Contrato', 'loan'),
      ('Data', 'date'),
      ('Capital', 'principal'),
      ('Estado', 'status'),
    ],
  ),
  'Reembolsos': _FinanceSpec(
    title: 'Reembolsos',
    subtitle: 'Pagamentos recebidos para liquidação de créditos.',
    icon: Icons.receipt_long_outlined,
    action: 'Registar pagamento',
    columns: [
      ('Data', 'date'),
      ('Crédito', 'loan'),
      ('Conta', 'account'),
      ('Método', 'method'),
      ('Valor', 'amount'),
    ],
  ),
  'Prestações Vencidas': _FinanceSpec(
    title: 'Prestações vencidas',
    subtitle: 'Prestações em atraso que exigem acompanhamento.',
    icon: Icons.warning_amber_rounded,
    columns: [
      ('Cliente', 'client'),
      ('Crédito', 'loan'),
      ('Prestação', 'installment'),
      ('Vencimento', 'date'),
      ('Dias', 'days'),
      ('Saldo', 'remaining'),
    ],
  ),
  'Ativos': _FinanceSpec(
    title: 'Ativos financeiros',
    subtitle: 'Disponibilidades financeiras mantidas nas contas activas.',
    icon: Icons.account_balance_outlined,
    columns: [
      ('Ativo', 'account'),
      ('Moeda', 'currency'),
      ('Valor', 'balance'),
      ('Estado', 'status'),
    ],
  ),
};
