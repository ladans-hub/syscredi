import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../domain/money.dart';
import '../domain/repository.dart';
import 'form.dart';

class PortfolioView extends StatefulWidget {
  const PortfolioView({required this.repository, super.key});
  final Repository repository;
  @override
  State<PortfolioView> createState() => _PortfolioState();
}

class _PortfolioState extends State<PortfolioView> {
  String query = '';
  String filter = 'Todos';
  final rows = <_Loan>[];
  bool loading = true;
  bool refreshing = false;
  bool _requestInFlight = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final initialLoad = rows.isEmpty;
    setState(() {
      loading = initialLoad;
      refreshing = !initialLoad;
      error = null;
    });
    try {
      final data = await widget.repository.get('/loans?limit=100&offset=0');
      if (!mounted) return;
      setState(() {
        rows
          ..clear()
          ..addAll(
            (data as List).map(
              (row) => _Loan.fromJson(Map<String, dynamic>.from(row as Map)),
            ),
          );
      });
    } catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      _requestInFlight = false;
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
    final shown = rows
        .where(
          (r) =>
              (filter == 'Todos' || r.status == filter) &&
              (query.isEmpty ||
                  '${r.client} ${r.reference}'.toLowerCase().contains(
                    query.toLowerCase(),
                  )),
        )
        .toList();
    return Column(
      children: [
        _title(
          context,
          Icons.wallet,
          'Carteira de crédito',
          'Contratos, exposição, saldos e desempenho da carteira.',
        ),
        const SizedBox(height: 18),
        _cards(context),
        const SizedBox(height: 18),
        _filters(),
        const SizedBox(height: 12),
        if (refreshing)
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (error != null)
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CenteredLoadingState(
              message: 'A carregar contratos da carteira…',
            ),
          )
        else if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nenhum contrato encontrado.'),
          )
        else
          for (final row in shown) _loanRow(context, row),
      ],
    );
  }

  Widget _title(BuildContext c, IconData icon, String title, String subtitle) =>
      Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(c).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(c).textTheme.headlineSmall),
                Text(subtitle),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () =>
                _toast(c, 'Relatório disponível na área de relatórios.'),
            icon: const Icon(Icons.download),
            label: const Text('Exportar'),
          ),
        ],
      );

  Widget _filters() => Wrap(
    spacing: 12,
    runSpacing: 10,
    children: [
      SizedBox(
        width: 280,
        child: TextField(
          decoration: const InputDecoration(
            labelText: 'Pesquisar cliente ou contrato',
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
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            DropdownMenuItem(value: 'Activo', child: Text('Activos')),
            DropdownMenuItem(value: 'Em atraso', child: Text('Em atraso')),
            DropdownMenuItem(value: 'Liquidado', child: Text('Liquidados')),
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
    ],
  );

  Widget _cards(BuildContext c) {
    final principal = rows.fold<int>(0, (sum, row) => sum + row.principalCents);
    final balance = rows.fold<int>(0, (sum, row) => sum + row.balanceCents);
    final active = rows.where((row) => row.status != 'Liquidado').length;
    final overdue = rows.where((row) => row.status == 'Em atraso').length;
    final overdueRate = active == 0 ? 0 : overdue * 100 / active;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _card(
          c,
          'Capital em carteira',
          _money(principal),
          Icons.attach_money_rounded,
          Colors.teal,
        ),
        _card(
          c,
          'Saldo por receber',
          _money(balance),
          Icons.wallet,
          Theme.of(c).colorScheme.primary,
        ),
        _card(
          c,
          'Taxa de atraso',
          '${overdueRate.toStringAsFixed(1)}%',
          Icons.warning_amber_rounded,
          Colors.orange,
        ),
        _card(
          c,
          'Contratos activos',
          active.toString().padLeft(2, '0'),
          Icons.document,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _card(
    BuildContext c,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(c).textTheme.bodySmall),
                  Text(value, style: Theme.of(c).textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _loanRow(BuildContext c, _Loan r) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(c).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.client,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(r.reference, style: Theme.of(c).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(child: Text(_money(r.balanceCents))),
        _badge(r.status),
        IconButton(
          tooltip: 'Abrir contrato',
          onPressed: () => _openContract(c, r),
          icon: const Icon(Icons.visibility_outlined),
        ),
      ],
    ),
  );

  Future<void> _openContract(BuildContext context, _Loan loan) async {
    try {
      final data = await widget.repository.get(
        '/loans/${loan.id}/installments',
      );
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Contrato ${loan.reference}'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final raw in data as List)
                    ListTile(
                      title: Text('Prestação ${(raw as Map)['number']}'),
                      subtitle: Text('${raw['due_date']}'),
                      trailing: Text(
                        _money(
                          (num.tryParse('${raw['remaining_cents']}') ?? 0)
                              .round(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (failure) {
      if (context.mounted) {
        await showFeedbackDialog(context, message: '$failure', success: false);
      }
    }
  }

  Widget _badge(String text) {
    final color = text == 'Em atraso'
        ? Colors.orange
        : text == 'Liquidado'
        ? Colors.teal
        : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _money(int cents) => money(cents);
  void _toast(BuildContext c, String m) => showFeedbackDialog(c, message: m);
}

class CollectionsView extends StatefulWidget {
  const CollectionsView({required this.repository, super.key});
  final Repository repository;
  @override
  State<CollectionsView> createState() => _CollectionsState();
}

class _CollectionsState extends State<CollectionsView> {
  String query = '';
  String filter = 'Todos';
  final searchController = TextEditingController();
  final rows = <_Collection>[];
  bool loading = true;
  bool refreshing = false;
  bool _requestInFlight = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  static String _normalized(String value) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const plain = 'aaaaaeeeeiiiiooooouuuuc';
    var result = value.toLowerCase().trim();
    for (var index = 0; index < accents.length; index++) {
      result = result.replaceAll(accents[index], plain[index]);
    }
    return result.replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    final initial = rows.isEmpty;
    setState(() {
      loading = initial;
      refreshing = !initial;
      error = null;
    });
    try {
      final loans = await widget.repository.get('/loans?limit=100&offset=0');
      final loaded = <_Collection>[];
      for (final raw in loans as List) {
        final loan = Map<String, dynamic>.from(raw as Map);
        final loanId = '${loan['id'] ?? ''}';
        if (loanId.isEmpty) continue;
        final installments = await widget.repository.get(
          '/loans/$loanId/installments',
        );
        for (final installmentRaw in installments as List) {
          final installment = Map<String, dynamic>.from(installmentRaw as Map);
          final remaining = _cents(
            installment['remaining_cents'] ??
                (_cents(installment['principal_cents']) +
                    _cents(installment['interest_cents']) -
                    _cents(installment['paid_cents'])),
          );
          if (remaining <= 0) continue;
          loaded.add(_Collection.fromJson(loan, installment, remaining));
        }
      }
      if (!mounted) return;
      setState(() {
        rows
          ..clear()
          ..addAll(loaded..sort((a, b) => a.dueDate.compareTo(b.dueDate)));
      });
    } catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      _requestInFlight = false;
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
    }
  }

  static int _cents(dynamic value) =>
      (num.tryParse('${value ?? 0}') ?? 0).round();
  @override
  Widget build(BuildContext c) {
    final normalizedQuery = _normalized(query);
    final shown = rows
        .where(
          (r) =>
              (filter == 'Todos' || r.status == filter) &&
              (normalizedQuery.isEmpty ||
                  _normalized(
                    [
                      r.client,
                      r.contract,
                      r.status,
                      'prestacao ${r.installmentNumber}',
                      _date(r.dueDate),
                      _money(r.remainingCents),
                    ].join(' '),
                  ).contains(normalizedQuery)),
        )
        .toList();
    return Column(
      children: [
        _title(c),
        const SizedBox(height: 18),
        _cards(c),
        const SizedBox(height: 18),
        _filters(),
        const SizedBox(height: 12),
        if (refreshing)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(),
          ),
        if (error != null)
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          )
        else if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CenteredLoadingState(
              message: 'A carregar a carteira de cobranças…',
            ),
          )
        else if (shown.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não existem prestações pendentes.'),
          ),
        for (final row in shown) _row(c, row),
      ],
    );
  }

  Widget _title(BuildContext c) => Row(
    children: [
      Icon(Icons.payments_outlined, size: 32, color: Colors.orange),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cobranças', style: Theme.of(c).textTheme.headlineSmall),
            const Text('Vencimentos, promessas, recebimentos e recuperação.'),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: refreshing || loading ? null : _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
      ),
    ],
  );
  Widget _filters() => Wrap(
    spacing: 12,
    runSpacing: 10,
    children: [
      SizedBox(
        width: 280,
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Pesquisar cliente ou contrato',
            hintText: 'Nome, contrato, prestação, estado ou valor',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpar pesquisa',
                    onPressed: () => setState(() {
                      searchController.clear();
                      query = '';
                    }),
                    icon: const Icon(Icons.close),
                  ),
          ),
          onChanged: (v) => setState(() => query = v),
          onSubmitted: (v) => setState(() => query = v),
        ),
      ),
      SizedBox(
        width: 190,
        child: DropdownButtonFormField<String>(
          initialValue: filter,
          decoration: const InputDecoration(labelText: 'Fila de cobrança'),
          items: const [
            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
            DropdownMenuItem(value: 'Em atraso', child: Text('Em atraso')),
            DropdownMenuItem(value: 'Vence hoje', child: Text('Vence hoje')),
            DropdownMenuItem(value: 'A vencer', child: Text('A vencer')),
          ],
          onChanged: (v) => setState(() => filter = v ?? 'Todos'),
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
  );
  Widget _cards(BuildContext c) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      _card(
        c,
        'Em atraso',
        _money(
          rows
              .where((row) => row.status == 'Em atraso')
              .fold(0, (sum, row) => sum + row.remainingCents),
        ),
        Icons.warning_amber_rounded,
        Colors.orange,
      ),
      _card(
        c,
        'Vence hoje',
        _money(
          rows
              .where((row) => row.status == 'Vence hoje')
              .fold(0, (sum, row) => sum + row.remainingCents),
        ),
        Icons.payments_outlined,
        Colors.teal,
      ),
      _card(
        c,
        'A vencer',
        '${rows.where((row) => row.status == 'A vencer').length}',
        Icons.calendar_today_outlined,
        Colors.blue,
      ),
      _card(
        c,
        'Saldo em cobrança',
        _money(rows.fold(0, (sum, row) => sum + row.remainingCents)),
        Icons.trending_up_rounded,
        Theme.of(c).colorScheme.primary,
      ),
    ],
  );
  Widget _card(BuildContext c, String l, String v, IconData i, Color color) =>
      SizedBox(
        width: 220,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(i, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l, style: Theme.of(c).textTheme.bodySmall),
                      Text(v, style: Theme.of(c).textTheme.titleLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget _row(BuildContext c, _Collection r) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Theme.of(c).colorScheme.outlineVariant),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.client,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(r.contract, style: Theme.of(c).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_money(r.remainingCents)),
              Text(
                'Prestação ${r.installmentNumber} · ${_date(r.dueDate)}',
                style: Theme.of(c).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _badge(r.status),
        IconButton(
          tooltip: 'Registar pagamento',
          onPressed: () => _registerPayment(c, r),
          icon: const Icon(Icons.payments_outlined),
        ),
        IconButton(
          tooltip: 'Consultar plano de prestações',
          onPressed: () => _showSchedule(c, r),
          icon: const Icon(Icons.event_available_outlined),
        ),
      ],
    ),
  );
  Widget _badge(String text) {
    final color = text == 'Em atraso'
        ? Theme.of(context).colorScheme.error
        : text == 'Vence hoje'
        ? Colors.orange
        : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _registerPayment(BuildContext context, _Collection row) async {
    final body = await form(context, widget.repository, 'Receber pagamento', [
      const Field(
        'accountId',
        'Conta de recebimento',
        resource: 'payment-accounts',
      ),
      Field(
        'amountCents',
        'Montante (MT)',
        kind: 'money',
        initial: (row.remainingCents / 100).toStringAsFixed(2),
      ),
      const Field(
        'method',
        'Canal',
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
      const Field('externalReference', 'Referência externa', optional: true),
    ]);
    if (body == null || !mounted) return;
    await runWithFeedback(
      context,
      () async {
        await widget.repository.write('POST', '/payments', {
          ...body,
          'loanId': row.loanId,
        });
        await _load();
      },
      title: 'A registar pagamento',
      successTitle: 'Pagamento registado',
      successMessage: 'O recebimento foi confirmado e o saldo actualizado.',
    );
  }

  Future<void> _showSchedule(BuildContext context, _Collection row) async {
    final installments = await widget.repository.get(
      '/loans/${row.loanId}/installments',
    );
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Plano · ${row.client}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final raw in installments as List)
                  ListTile(
                    title: Text('Prestação ${(raw as Map)['number']}'),
                    subtitle: Text('${raw['due_date']}'),
                    trailing: Text(_money(_cents(raw['remaining_cents']))),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _money(int cents) => money(cents);
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _Loan {
  const _Loan(
    this.id,
    this.reference,
    this.client,
    this.principalCents,
    this.balanceCents,
    this.status,
  );
  final String id, reference, client, status;
  final int principalCents, balanceCents;

  factory _Loan.fromJson(Map<String, dynamic> row) {
    final rawStatus = '${row['status'] ?? ''}';
    final status = rawStatus == 'settled' || rawStatus == 'paid'
        ? 'Liquidado'
        : rawStatus == 'overdue'
        ? 'Em atraso'
        : 'Activo';
    return _Loan(
      '${row['id'] ?? ''}',
      '${row['contract_number'] ?? row['number'] ?? row['id'] ?? ''}',
      '${row['client_name'] ?? 'Cliente'}',
      (num.tryParse('${row['principal_cents']}') ?? 0).round(),
      (num.tryParse('${row['balance_cents']}') ?? 0).round(),
      status,
    );
  }
}

class _Collection {
  const _Collection({
    required this.loanId,
    required this.contract,
    required this.client,
    required this.installmentNumber,
    required this.remainingCents,
    required this.dueDate,
    required this.status,
  });
  final String loanId, contract, client, status;
  final int installmentNumber, remainingCents;
  final DateTime dueDate;

  factory _Collection.fromJson(
    Map<String, dynamic> loan,
    Map<String, dynamic> installment,
    int remaining,
  ) {
    final due =
        DateTime.tryParse('${installment['due_date']}') ?? DateTime.now();
    final today = DateTime.now();
    final date = DateTime(due.year, due.month, due.day);
    final current = DateTime(today.year, today.month, today.day);
    final status = date.isBefore(current)
        ? 'Em atraso'
        : date == current
        ? 'Vence hoje'
        : 'A vencer';
    return _Collection(
      loanId: '${loan['id'] ?? ''}',
      contract: '${loan['contract_number'] ?? loan['number'] ?? loan['id']}',
      client: '${loan['client_name'] ?? 'Cliente'}',
      installmentNumber: int.tryParse('${installment['number']}') ?? 0,
      remainingCents: remaining,
      dueDate: date,
      status: status,
    );
  }
}
