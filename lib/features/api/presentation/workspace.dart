import 'package:syscredi/core/widgets/equal_button_group.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import '../../../app/theme/app_theme.dart';
import '../../../core/csv/csv_codec.dart';
import '../domain/repository.dart';
import '../domain/money.dart';
import 'session_view_model.dart';
import 'form.dart';
import 'navigation.dart';
import 'search_dialog.dart';

const _stages = {
  'documentation': 'Documentação',
  'analysis': 'Análise',
  'committee': 'Comité',
  'approved': 'Aprovado',
  'rejected': 'Recusado',
  'disbursed': 'Desembolsado',
};
const _roles = {
  'operator': 'Operador',
  'analyst': 'Analista',
  'manager': 'Gestor',
};
const _methods = {
  'cash': 'Caixa',
  'bank_transfer': 'Transferência bancária',
  'mpesa': 'M-Pesa',
  'emola': 'e-Mola',
  'mkesh': 'mKesh',
};
const _labels = {
  'id': 'Referência',
  'name': 'Nome',
  'phone': 'Telefone',
  'document': 'Documento',
  'activity': 'Actividade',
  'location': 'Localização',
  'client_name': 'Cliente',
  'client_id': 'Referência do cliente',
  'product_name': 'Produto',
  'product_id': 'Referência do produto',
  'amount_cents': 'Montante',
  'principal_cents': 'Capital',
  'balance_cents': 'Saldo',
  'paid_cents': 'Pago',
  'interest_cents': 'Juros',
  'remaining_cents': 'Por pagar',
  'opening_balance_cents': 'Saldo inicial',
  'max_amount_cents': 'Limite de crédito',
  'annual_rate_bps': 'Taxa anual (pontos-base)',
  'months': 'Prazo (meses)',
  'min_months': 'Prazo mínimo',
  'max_months': 'Prazo máximo',
  'stage': 'Etapa',
  'status': 'Estado',
  'role': 'Perfil',
  'active': 'Activo',
  'archived': 'Arquivado',
  'version': 'Versão',
  'kyc_expires_at': 'Validade documental',
  'kyc_reviewed_by': 'Revisão documental por',
  'created_at': 'Criado em',
  'updated_at': 'Actualizado em',
  'loan_id': 'Contrato',
  'request_id': 'Pedido',
  'account_id': 'Conta',
  'payment_id': 'Pagamento',
  'actor_id': 'Responsável',
  'officer_id': 'Responsável',
  'method': 'Canal',
  'external_reference': 'Referência externa',
  'reason': 'Motivo',
  'source': 'Origem',
  'source_id': 'Referência de origem',
  'action': 'Operação',
  'entity_id': 'Registo',
  'details': 'Detalhes',
  'currency': 'Moeda',
  'number': 'Prestação',
  'due_date': 'Vencimento',
  'snapshot': 'Condições do contrato',
  'lines': 'Lançamentos',
  'account': 'Conta contabilística',
  'debit': 'Débito (centavos)',
  'credit': 'Crédito (centavos)',
  'client': 'Cliente',
  'product': 'Produto',
  'schedule': 'Prestações',
  'principalCents': 'Capital (centavos)',
  'interestCents': 'Juros (centavos)',
  'amountCents': 'Montante (centavos)',
  'dueDate': 'Vencimento',
};

class _Section {
  const _Section(this.path, this.title, this.icon);
  final String path, title;
  final IconData icon;
}

class _FluentCard extends StatefulWidget {
  const _FluentCard({required this.child});
  final Widget child;

  @override
  State<_FluentCard> createState() => _FluentCardState();
}

class _FluentCardState extends State<_FluentCard> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.primary;
    final surface = hovered
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLow;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      cursor: SystemMouseCursors.basic,
      child: Material(
        color: surface,
        elevation: hovered ? 2 : 1,
        shadowColor: scheme.shadow.withValues(alpha: .10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hovered ? border : scheme.outlineVariant,
            width: hovered ? 1.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: null,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return scheme.primary.withValues(alpha: .10);
            }
            if (states.contains(WidgetState.hovered)) {
              return scheme.primary.withValues(alpha: .04);
            }
            return null;
          }),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _DashboardChartPainter extends CustomPainter {
  _DashboardChartPainter(this.values, this.primary, this.secondary);
  final List<num> values;
  final Color primary, secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE9EEF4)
      ..strokeWidth = 1;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.length < 2) return;
    final maxValue = values.fold<num>(1, (a, b) => a > b ? a : b).toDouble();
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height -
          (values[i].toDouble() / maxValue * size.height * .86) -
          5;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX = size.width * (i - 1) / (values.length - 1);
        final previousY =
            size.height -
            (values[i - 1].toDouble() / maxValue * size.height * .86) -
            5;
        final midpoint = (previousX + x) / 2;
        path.cubicTo(midpoint, previousY, midpoint, y, x, y);
      }
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            primary.withValues(alpha: .18),
            primary.withValues(alpha: .01),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = primary
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    final baseline = Paint()
      ..color = secondary
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height - 4),
      Offset(size.width, size.height - 4),
      baseline,
    );
  }

  @override
  bool shouldRepaint(covariant _DashboardChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.primary != primary;
}

class Workspace extends StatefulWidget {
  const Workspace({required this.session, this.onTheme, super.key});
  final WorkspaceSession session;
  final ValueChanged<ThemeMode>? onTheme;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  Repository get api => widget.session.api;
  List<_Section> get sections => [
    if (widget.session.manager)
      const _Section('users', 'Utilizadores', Icons.manage_accounts_outlined),
    if (widget.session.analyst || widget.session.manager)
      const _Section('audit', 'Auditoria', Icons.history),
    const _Section('dashboard', 'Início', Icons.dashboard_outlined),
    const _Section('simulator', 'Simulador', Icons.calculate_outlined),
    const _Section('clients', 'Clientes', Icons.people_outline),
    const _Section('businesses', 'Empresas', Icons.business_outlined),
    const _Section('co-signers', 'Co-assinantes', Icons.group_outlined),
    const _Section('products', 'Produtos', Icons.category_outlined),
    const _Section('requests', 'Pedidos', Icons.assignment_outlined),
    const _Section('loans', 'Carteira', Icons.account_balance_outlined),
    const _Section('contracts', 'Contratos', Icons.description_outlined),
    const _Section('payments', 'Pagamentos', Icons.payments_outlined),
    const _Section('receipts', 'Recibos', Icons.receipt_long_outlined),
    const _Section('payment-reversals', 'Estornos', Icons.undo_outlined),
    const _Section('reports', 'Relatórios', Icons.analytics_outlined),
    if (widget.session.analyst)
      const _Section('aml-alerts', 'Compliance AML', Icons.policy_outlined),
    if (widget.session.analyst) ...[
      const _Section(
        'field-visits',
        'Visitas de campo',
        Icons.location_on_outlined,
      ),
      const _Section('documents', 'Documentos', Icons.folder_outlined),
      const _Section('client-guarantors', 'Garantias', Icons.group_outlined),
      const _Section('risk-scores', 'Risco', Icons.assessment_outlined),
    ],
    if (widget.session.manager) ...[
      const _Section(
        'accounts',
        'Contas',
        Icons.account_balance_wallet_outlined,
      ),
      const _Section('cash-entries', 'Tesouraria', Icons.swap_horiz),
      const _Section('journal', 'Contabilidade', Icons.menu_book_outlined),
      const _Section(
        'accounting-periods',
        'Períodos contabilísticos',
        Icons.event_available_outlined,
      ),
      const _Section(
        'reconciliations',
        'Reconciliações',
        Icons.compare_arrows_outlined,
      ),
      const _Section(
        'account-transfers',
        'Transferências',
        Icons.swap_horiz_outlined,
      ),
      const _Section(
        'organization-settings',
        'Organização',
        Icons.settings_outlined,
      ),
      const _Section(
        'subscription-history',
        'Subscrição',
        Icons.card_membership_outlined,
      ),
      const _Section('sync-operations', 'Sincronização', Icons.sync_outlined),
      const _Section('backup-archives', 'Backups', Icons.backup_outlined),
      const _Section(
        'retention-policies',
        'Retenção',
        Icons.delete_sweep_outlined,
      ),
      const _Section('settings', 'Configurações', Icons.settings_outlined),
    ],
    const _Section('pending', 'Pendências', Icons.cloud_upload_outlined),
  ];
  String route = 'dashboard';
  int offset = 0, generation = 0;
  List<Json> rows = [];
  Json metrics = {};
  List<PendingWrite> pending = [];
  bool loading = true, busy = false, foreground = true;
  String? error;
  DateTime? updated;
  Timer? timer;
  final search = TextEditingController();
  String clientCategory = 'Indivíduos';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
    // Refresh is triggered on foreground and by the navbar action. A periodic
    // timer would keep Flutter's settle loop alive indefinitely in widget tests.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground && !loading && !busy) load();
  }

  @override
  void dispose() {
    generation++;
    timer?.cancel();
    search.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    final current = ++generation, target = route;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.session.verify();
      if (!mounted || current != generation) return;
      final value = target == 'pending'
          ? await api.pending()
          : await api.get(
              target == 'dashboard' || target == 'simulator'
                  ? '/dashboard'
                  : target == 'reports'
                  ? '/reports/portfolio'
                  : target == 'settings'
                  ? '/organization-settings?limit=50&offset=$offset&q=${Uri.encodeQueryComponent(search.text.trim())}'
                  : '/$target?limit=50&offset=$offset&q=${Uri.encodeQueryComponent(search.text.trim())}',
            );
      if (!mounted || current != generation) return;
      setState(() {
        if (target == 'pending') {
          pending = value as List<PendingWrite>;
        } else if (target == 'dashboard' ||
            target == 'simulator' ||
            target == 'reports') {
          metrics = Map<String, dynamic>.from(value);
        } else {
          rows = (value as List)
              .map((r) => Map<String, dynamic>.from(r))
              .toList();
        }
        updated = DateTime.now();
      });
    } catch (e) {
      if (mounted && current == generation) setState(() => error = '$e');
    } finally {
      if (mounted && current == generation) setState(() => loading = false);
    }
  }

  void select(String next) {
    if (busy) return;
    setState(() {
      route = next;
      offset = 0;
      rows = [];
      metrics = {};
      pending = [];
      updated = null;
      search.clear();
    });
    load();
  }

  Future<void> mutate(String method, String path, Json body) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await api.write(method, path, body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operação confirmada no servidor.')),
        );
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível confirmar. Consulte Pendências antes de repetir.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
      }
    }
  }

  Future<void> _closeAccountingPeriod() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Encerrar período contabilístico'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Mês (AAAA-MM)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );
    final month = controller.text.trim();
    controller.dispose();
    if (confirmed != true || month.isEmpty) return;
    await mutate('POST', '/accounting-periods/$month/close', {});
  }

  Future<void> create() async {
    final fields = switch (route) {
      'clients' => _clientFields(),
      'businesses' => const [
        Field('legalName', 'Denominação legal'),
        Field('tradingName', 'Nome comercial'),
        Field('registrationNumber', 'NUEL / Registo'),
        Field('taxNumber', 'NUIT'),
        Field('phone', 'Telefone'),
        Field('address', 'Endereço'),
        Field('activity', 'Actividade'),
        Field('representative', 'Representante'),
      ],
      'co-signers' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('name', 'Nome'),
        Field('document', 'Documento'),
        Field('phone', 'Telefone'),
        Field('relationship', 'Relação'),
      ],
      'products' => const [
        Field('name', 'Nome'),
        Field('annualRateBps', 'Taxa anual (%)', kind: 'rate'),
        Field('minMonths', 'Prazo mínimo (meses)', kind: 'int', initial: '1'),
        Field('maxMonths', 'Prazo máximo (meses)', kind: 'int', initial: '12'),
        Field('maxAmountCents', 'Limite (MT)', kind: 'money'),
      ],
      'requests' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('productId', 'Produto', resource: 'products'),
        Field('amountCents', 'Capital (MT)', kind: 'money'),
        Field('months', 'Prazo (meses)', kind: 'int'),
      ],
      'accounts' => const [
        Field('name', 'Nome da conta'),
        Field(
          'openingBalanceCents',
          'Saldo inicial (MT)',
          kind: 'money',
          initial: '0',
        ),
      ],
      'payments' => _paymentFields(),
      'aml-alerts' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('reference', 'Referência'),
        Field('reason', 'Motivo'),
        Field(
          'severity',
          'Severidade',
          options: {'low': 'Baixa', 'medium': 'Média', 'high': 'Alta'},
          initial: 'medium',
        ),
      ],
      'field-visits' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('visitedAt', 'Data da visita', kind: 'date'),
        Field('notes', 'Notas'),
      ],
      'documents' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('documentType', 'Tipo de documento'),
        Field('storageKey', 'Chave do ficheiro'),
        Field('checksum', 'Checksum'),
      ],
      'client-guarantors' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('name', 'Nome'),
        Field('document', 'Documento'),
        Field('phone', 'Telefone'),
        Field('relationship', 'Relação'),
      ],
      'risk-scores' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('score', 'Pontuação', kind: 'int'),
        Field('band', 'Faixa'),
      ],
      'reconciliations' => const [
        Field('accountId', 'Conta', resource: 'accounts'),
        Field('expectedCents', 'Saldo esperado (MT)', kind: 'money'),
        Field('actualCents', 'Saldo real (MT)', kind: 'money'),
        Field('notes', 'Notas', optional: true),
      ],
      'account-transfers' => const [
        Field('fromAccountId', 'Conta origem', resource: 'accounts'),
        Field('toAccountId', 'Conta destino', resource: 'accounts'),
        Field('amountCents', 'Montante (MT)', kind: 'money'),
        Field('reference', 'Referência', optional: true),
      ],
      'organization-settings' => const [
        Field('key', 'Chave'),
        Field('value', 'Valor JSON'),
      ],
      'subscription-history' => const [
        Field('plan', 'Plano'),
        Field('codeFingerprint', 'Código fingerprint'),
        Field('expiresAt', 'Expira em', kind: 'date'),
      ],
      'sync-operations' => const [
        Field('clientOperationId', 'ID da operação'),
        Field('operation', 'Operação'),
        Field('payloadHash', 'Hash do payload'),
      ],
      'backup-archives' => const [
        Field('storageKey', 'Chave do arquivo'),
        Field('checksum', 'Checksum'),
        Field('sizeBytes', 'Tamanho (bytes)', kind: 'int'),
      ],
      'retention-policies' => const [
        Field('key', 'Chave'),
        Field('days', 'Dias', kind: 'int'),
      ],
      'users' => const [
        Field('email', 'Email do membro'),
        Field('name', 'Nome'),
        Field(
          'role',
          'Perfil',
          options: {
            'operator': 'Operador',
            'analyst': 'Analista',
            'guarantor': 'Avalista',
          },
          initial: 'operator',
        ),
      ],
      _ => <Field>[],
    };
    final data = await form(
      context,
      api,
      route == 'users' ? 'Autorizar utilizador existente' : 'Novo registo',
      fields,
    );
    if (data != null && mounted) {
      await mutate(
        route == 'users' ? 'POST' : 'POST',
        route == 'users' ? '/organizations/members/invite' : '/$route',
        data,
      );
    }
  }

  Future<void> importClients() async {
    final input = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Importar indivíduos por CSV'),
        content: SizedBox(
          width: 650,
          child: TextField(
            controller: input,
            maxLines: 12,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Cole o CSV',
              hintText: 'nome,telemovel,documento,actividade,localidade',
            ),
          ),
        ),
        actions: [
          EqualButtonGroup(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Importar'),
              ),
            ],
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      final records = decodeCsv(input.text);
      if (records.length < 2) throw const FormatException('CSV sem registos.');
      final header = records.first.map((v) => v.trim().toLowerCase()).toList();
      final required = [
        'nome',
        'telemovel',
        'documento',
        'actividade',
        'localizacao',
      ];
      for (final field in required) {
        if (!header.contains(field)) {
          throw FormatException('Coluna obrigatória: $field.');
        }
      }
      setState(() => busy = true);
      for (final values in records.skip(1)) {
        final row = {
          for (var i = 0; i < header.length && i < values.length; i++)
            header[i]: values[i].trim(),
        };
        await api.write('POST', '/clients', {
          'name': row['nome'] ?? '',
          'phone': row['telemovel'] ?? '',
          'document': row['documento'] ?? '',
          'activity': row['actividade'] ?? '',
          'location': row['localizacao'] ?? '',
          'clientType': 'individual',
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV importado no servidor.')),
        );
      }
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      input.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  List<Field> _clientFields([Json? row]) => [
    Field(
      'clientType',
      'Tipo de cliente',
      options: const {'individual': 'Indivíduo', 'business': 'Empresa'},
      initial: row?['client_type']?.toString() ?? 'individual',
    ),
    for (final (key, label) in [
      ('name', 'Nome completo'),
      ('phone', 'Telefone'),
      ('document', 'Documento'),
      ('activity', 'Actividade'),
      ('location', 'Localização'),
    ])
      Field(key, label, initial: row?[key]?.toString() ?? ''),
  ];
  List<Field> _paymentFields([String? loanId]) => [
    if (loanId == null) const Field('loanId', 'Contrato', resource: 'loans'),
    const Field(
      'accountId',
      'Conta de recebimento',
      resource: 'payment-accounts',
    ),
    const Field('amountCents', 'Montante (MT)', kind: 'money'),
    const Field('method', 'Canal', options: _methods, initial: 'cash'),
    const Field(
      'externalReference',
      'Referência externa (obrigatória fora de caixa)',
      optional: true,
    ),
  ];
  Future<void> editClient(Json row) async {
    final body = await form(context, api, 'Editar cliente', [
      ..._clientFields(row),
      Field(
        'archived',
        'Situação',
        kind: 'bool',
        options: const {'false': 'Activo', 'true': 'Arquivado'},
        initial: row['archived'].toString(),
      ),
    ]);
    if (body != null && mounted) {
      await mutate('PUT', '/clients/${row['id']}', {
        ...body,
        'version': row['version'],
      });
    }
  }

  Future<void> editBusiness(Json row) async {
    final body = await form(context, api, 'Editar empresa', [
      Field(
        'legalName',
        'Denominação legal',
        initial: '${row['legal_name'] ?? ''}',
      ),
      Field(
        'tradingName',
        'Nome comercial',
        initial: '${row['trading_name'] ?? ''}',
      ),
      Field(
        'registrationNumber',
        'NUEL / Registo',
        initial: '${row['registration_number'] ?? ''}',
      ),
      Field('taxNumber', 'NUIT', initial: '${row['tax_number'] ?? ''}'),
      Field('phone', 'Telefone', initial: '${row['phone'] ?? ''}'),
      Field('address', 'Endereço', initial: '${row['address'] ?? ''}'),
      Field('activity', 'Actividade', initial: '${row['activity'] ?? ''}'),
      Field(
        'representative',
        'Representante',
        initial: '${row['representative'] ?? ''}',
      ),
      Field(
        'active',
        'Estado',
        kind: 'bool',
        options: const {'true': 'Activa', 'false': 'Inactiva'},
        initial: '${row['active'] ?? true}',
      ),
    ]);
    if (body != null && mounted) {
      await mutate('PATCH', '/businesses/${row['id']}', {
        ...body,
        'version': row['version'],
      });
    }
  }

  Future<void> editCoSigner(Json row) async {
    final body = await form(context, api, 'Editar co-assinante', [
      Field(
        'clientId',
        'Cliente',
        resource: 'clients',
        initial: '${row['client_id'] ?? ''}',
      ),
      Field('name', 'Nome', initial: '${row['name'] ?? ''}'),
      Field('document', 'Documento', initial: '${row['document'] ?? ''}'),
      Field('phone', 'Telefone', initial: '${row['phone'] ?? ''}'),
      Field('relationship', 'Relação', initial: '${row['relationship'] ?? ''}'),
    ]);
    if (body != null && mounted) {
      await mutate('PATCH', '/co-signers/${row['id']}', {
        ...body,
        'version': row['version'],
      });
    }
  }

  Future<void> kyc(Json row) async {
    final body = await form(context, api, 'Rever identificação', const [
      Field('expiresAt', 'Validade do documento (AAAA-MM-DD)', kind: 'date'),
    ]);
    if (body != null && mounted) {
      await mutate('POST', '/clients/${row['id']}/kyc', body);
    }
  }

  Future<void> decide(Json row) async {
    const next = {
      'documentation': 'analysis',
      'analysis': 'committee',
      'committee': 'approved',
    };
    if (!next.containsKey(row['stage'])) return;
    final stage = next[row['stage']]!;
    final body = await form(context, api, 'Decisão do pedido', [
      Field(
        'stage',
        'Decisão',
        options: {stage: _stages[stage]!, 'rejected': 'Recusar'},
        initial: stage,
      ),
      const Field(
        'reason',
        'Motivo (obrigatório para recusar)',
        optional: true,
      ),
    ]);
    if (body != null && mounted) {
      await mutate('PATCH', '/requests/${row['id']}/stage', {
        ...body,
        'version': row['version'],
      });
    }
  }

  Future<void> disburse(Json row) async {
    final body = await form(
      context,
      api,
      'Desembolsar ${money(row['amount_cents'])}',
      const [
        Field('accountId', 'Conta de desembolso', resource: 'payment-accounts'),
      ],
    );
    if (body != null && mounted) {
      await mutate('POST', '/requests/${row['id']}/disburse', body);
    }
  }

  Future<void> pay(Json row) async {
    final body = await form(
      context,
      api,
      'Receber pagamento',
      _paymentFields(row['id']),
    );
    if (body != null && mounted) {
      await mutate('POST', '/payments', {...body, 'loanId': row['id']});
    }
  }

  Future<void> reversePayment(Json row) async {
    final body = await form(context, api, 'Estornar pagamento', const [
      Field('reason', 'Motivo do estorno'),
    ]);
    if (body != null && mounted) {
      await mutate('POST', '/payments/${row['id']}/reverse', body);
    }
  }

  Future<void> editUser(Json row) async {
    final body = await form(context, api, 'Gerir acesso', [
      Field('name', 'Nome', initial: row['name']),
      Field('role', 'Perfil', options: _roles, initial: row['role']),
      Field(
        'active',
        'Acesso',
        kind: 'bool',
        options: const {'true': 'Activo', 'false': 'Desactivado'},
        initial: row['active'].toString(),
      ),
    ]);
    if (body != null && mounted) {
      await mutate('PUT', '/users', {...body, 'userId': row['id']});
    }
  }

  Future<void> schedule(Json row) async {
    try {
      final data = await api.get('/loans/${row['id']}/installments');
      if (mounted) {
        await details({'schedule': data}, title: 'Plano de prestações');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String display(String key, dynamic value) {
    if (value == null) return '—';
    if (key.endsWith('_cents')) return money(value);
    if (key == 'annual_rate_bps') return '${intValue(value) / 100}%';
    if (value is bool) return value ? 'Sim' : 'Não';
    if (key == 'stage') return _stages[value] ?? '$value';
    if (key == 'role') return _roles[value] ?? '$value';
    if (key == 'method') return _methods[value] ?? '$value';
    if (key == 'status') {
      return {'active': 'Activo', 'settled': 'Liquidado'}[value] ?? '$value';
    }
    return '$value';
  }

  List<Widget> describe(dynamic value) {
    if (value is List) {
      return [
        for (var i = 0; i < value.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${i + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...describe(value[i]),
          const Divider(),
        ],
      ];
    }
    if (value is Map) {
      return [
        for (final entry in value.entries)
          if (entry.value is Map || entry.value is List)
            ExpansionTile(
              title: Text(_labels[entry.key] ?? entry.key),
              children: describe(entry.value),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: SelectableText(
                '${_labels[entry.key] ?? entry.key}: ${display(entry.key, entry.value)}',
              ),
            ),
      ];
    }
    return [Text('$value')];
  }

  Future<void> details(Json row, {String title = 'Detalhes'}) =>
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: describe(row),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
  Future<void> retry(PendingWrite operation) async {
    setState(() => busy = true);
    try {
      await api.retry(operation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Resultado confirmado. Actualize a carteira para consultar o saldo.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
      }
    }
  }

  Future<void> cancelPending(PendingWrite operation) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar operação pendente?'),
        content: const Text(
          'O servidor só cancela se a operação ainda não tiver sido executada. Se já foi concluída, será apresentado o resultado confirmado; não se trata de um estorno.',
        ),
        actions: [
          EqualButtonGroup(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Voltar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Verificar e cancelar'),
              ),
            ],
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => busy = true);
    try {
      final status = await api.cancel(operation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? 'A operação já foi concluída. Consulte os dados actualizados.'
                  : 'Cancelamento confirmado. A operação não será executada.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
      }
    }
  }

  bool get canCreate =>
      [
        'clients',
        'businesses',
        'co-signers',
        'requests',
        'payments',
      ].contains(route) ||
      (widget.session.analyst &&
          [
            'aml-alerts',
            'field-visits',
            'documents',
            'client-guarantors',
            'risk-scores',
          ].contains(route)) ||
      (widget.session.manager &&
          [
            'products',
            'accounts',
            'users',
            'reconciliations',
            'account-transfers',
            'organization-settings',
            'subscription-history',
            'sync-operations',
            'backup-archives',
            'retention-policies',
          ].contains(route));

  Widget _dashboardBody() {
    final activeClients = '${metrics['clients'] ?? 248}';
    final pendingRequests = '${metrics['pending_requests'] ?? 18}';
    final outstanding = money(metrics['outstanding_cents'] ?? 186450000);
    return LayoutBuilder(
      builder: (context, viewport) {
        final scheme = Theme.of(context).colorScheme;
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
                        'Visão geral',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.8,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Acompanhe o desempenho da sua carteira em tempo real.',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (viewport.maxWidth > 700) _periodChip(),
              ],
            ),
            const SizedBox(height: 22),
            GridView.count(
              crossAxisCount: viewport.maxWidth >= 1000
                  ? 4
                  : viewport.maxWidth >= 540
                  ? 2
                  : 1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 22,
              mainAxisSpacing: 22,
              childAspectRatio: viewport.maxWidth < 540 ? 2.2 : 1.52,
              children: [
                _remoteKpi(
                  'Créditos concedidos',
                  '114.000,00 MZN',
                  '20 este mês',
                  Icons.credit_card_outlined,
                  scheme.primary,
                ),
                _remoteKpi(
                  'Capital em atraso',
                  '29.647,00 MZN',
                  '7 contratos',
                  Icons.warning_amber_rounded,
                  scheme.error,
                ),
                _remoteKpi(
                  'Juros em atraso',
                  '6.457,00 MZN',
                  '7 contratos',
                  Icons.error_outline_rounded,
                  scheme.error,
                ),
                _remoteKpi(
                  'Clientes activos',
                  activeClients,
                  '9 novos este mês',
                  Icons.people_alt_outlined,
                  scheme.secondary,
                ),
                _remoteKpi(
                  'Desembolso diário',
                  '3.000,00 MZN',
                  '1 operação',
                  Icons.payments_outlined,
                  scheme.tertiary,
                ),
                _remoteKpi(
                  'Reembolso diário',
                  '6.500,00 MZN',
                  '2 operações',
                  Icons.assignment_turned_in_outlined,
                  scheme.secondary,
                ),
                _remoteKpi(
                  'Carteira activa',
                  outstanding,
                  'saldo por receber',
                  Icons.account_balance_wallet_outlined,
                  scheme.primary,
                ),
                _remoteKpi(
                  'Pedidos pendentes',
                  pendingRequests,
                  'aguardam decisão',
                  Icons.description_outlined,
                  scheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _dashboardSplit(viewport.maxWidth),
            const SizedBox(height: 20),
            _dashboardPanels(viewport.maxWidth),
            const SizedBox(height: 20),
            _chartPanel(
              'Despesas 2026',
              'Despesas pendentes',
              'Despesas pagas',
              scheme.error,
              scheme.secondary,
              [0, 0, 0, 0, 1800, 2400, 8600, 1200, 0, 0, 0, 0],
            ),
            const SizedBox(height: 20),
            _chartPanel(
              'Empréstimos pagos / pendentes 2026',
              'Empréstimos pagos',
              'Empréstimos pendentes',
              scheme.secondary,
              scheme.error,
              [0, 0, 0, 0, 100, 315, 265, 305, 60, 0, 0, 0],
            ),
          ],
        );
      },
    );
  }

  Widget _periodChip() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 16),
          SizedBox(width: 8),
          Text(
            'Setembro 2026',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dashboardSplit(double width) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: width >= 900 ? 2 : 1,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: width >= 900 ? 1.65 : 1.8,
      children: [
        _projectionCard('Projecção pendente', scheme.error, [
          ('Capital a ser devolvido', '296.840,00 MZN'),
          ('Juros a ser devolvido', '87.152,00 MZN'),
          ('Mora a ser paga', '0,00 MZN'),
          ('Total a ser pago', '383.992,00 MZN'),
        ]),
        _projectionCard('Projecção paga', scheme.secondary, [
          ('Capital pago', '33.101,40 MZN'),
          ('Juros pago', '26.764,95 MZN'),
          ('Mora paga', '3.959,65 MZN'),
          ('Multa paga', '0,00 MZN'),
          ('Total pago', '63.826,00 MZN'),
        ]),
      ],
    );
  }

  Widget _projectionCard(
    String title,
    Color color,
    List<(String, String)> values,
  ) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 14),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.$1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      value.$2,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: .72,
                    minHeight: 7,
                    backgroundColor: color.withValues(alpha: .10),
                    color: color,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _dashboardPanels(double width) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: width >= 1050
          ? 3
          : width >= 650
          ? 2
          : 1,
      crossAxisSpacing: 18,
      mainAxisSpacing: 18,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: width >= 1050 ? 1.05 : 0.9,
      children: [
        _riskPanel(),
        _listPanel('Reembolso mensal', [
          ('Júlio Custódio', '900,00 MZN'),
          ('Silvério João Muaquiqua', '3.250,00 MZN'),
          ('Francisco Adelino Rui', '3.250,00 MZN'),
          ('Agostinho Querino', '5.200,00 MZN'),
        ], scheme.secondary),
        _listPanel('Desembolso mensal', [
          ('Pascoal João Muaquiquia', '3.000,00 MZN'),
          ('Armando Manuel António', '5.000,00 MZN'),
          ('Júlio Custódio', '2.500,00 MZN'),
          ('Edson Mário Morais', '1.000,00 MZN'),
        ], scheme.error),
        _listPanel('Gestão de logs', [
          ('Naveia Muaquiquia João', 'login'),
          ('Naveia Muaquiquia João', 'logout'),
          ('Loide Janeth Ligia', 'submissão'),
          ('Loide Janeth Ligia', 'login'),
        ], scheme.primary),
        _distributionPanel('Distribuição das contas', Icons.bar_chart_rounded),
        _distributionPanel(
          'Distribuição dos clientes',
          Icons.pie_chart_outline_rounded,
        ),
      ],
    );
  }

  Widget _riskPanel() {
    final scheme = Theme.of(context).colorScheme;
    return _surface(
      SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Carteira de clientes em risco',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            for (final item in [
              ('Classe I', '1 até 30 dias', .62, 5, scheme.onSurfaceVariant),
              ('Classe I.I', '31 até 90 dias', .42, 1, scheme.secondary),
              ('Classe II', '90 até 180 dias', .82, 0, scheme.error),
              ('Classe II.I', '180 até 260 dias', .62, 0, scheme.tertiary),
              ('Classe III', '260 até 520 dias', .82, 0, scheme.error),
              (
                'Classe IV',
                '1041 dias em diante',
                .82,
                0,
                scheme.onSurfaceVariant,
              ),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.$1} (${item.$2})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${item.$4}',
                          style: TextStyle(
                            color: item.$5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: item.$3,
                        minHeight: 7,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        color: item.$5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _listPanel(String title, List<(String, String)> items, Color color) =>
      _surface(
        SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              for (final item in items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'NR Crédito · actualizado hoje',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                  trailing: Text(
                    item.$2,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  Widget _distributionPanel(String title, IconData icon) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Center(
          child: Icon(
            icon,
            size: 76,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            'Masculino 79,8%  ·  Feminino 17,2%',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chartPanel(
    String title,
    String first,
    String second,
    Color firstColor,
    Color secondColor,
    List<num> values,
  ) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(first, firstColor),
            const SizedBox(width: 26),
            _legend(second, secondColor),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: CustomPaint(
            painter: _DashboardChartPainter(values, firstColor, secondColor),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Jan',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Abr',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Jul',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Out',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Dez',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _legend(String label, Color color) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
  Widget _surface(Widget child) => _FluentCard(child: child);

  Widget _remoteKpi(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDarkBlue = color.b > color.r + .08 && color.b > color.g + .08;
    final accent =
        Theme.of(context).brightness == Brightness.dark &&
            (color.computeLuminance() < .20 || isDarkBlue)
        ? scheme.onSurface.withValues(alpha: .82)
        : color;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: .08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: accent, size: 27),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: accent,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReport(
    String path,
    String filename,
    String mimeType,
  ) async {
    try {
      final bytes = await api.bytes(path);
      if (!mounted) return;
      final location = await getSaveLocation(suggestedName: filename);
      if (location == null) return;
      await XFile.fromData(bytes, mimeType: mimeType).saveTo(location.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Relatório guardado em ${location.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível gerar o relatório: $e')),
        );
      }
    }
  }

  Widget _settingsBody() {
    final visuals = brandVisuals.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Definições',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Personalize o espaço de gestão da sua instituição.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aparência',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final mode in [
                      ThemeMode.system,
                      ThemeMode.light,
                      ThemeMode.dark,
                    ])
                      ChoiceChip(
                        label: Text(
                          mode == ThemeMode.system
                              ? 'Sistema'
                              : mode == ThemeMode.light
                              ? 'Claro'
                              : 'Escuro',
                        ),
                        selected: themeMode.value == mode,
                        onSelected: (_) {
                          themeMode.value = mode;
                          widget.onTheme?.call(mode);
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Fonte do sistema ou fonte premium',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: visuals.fontFamily,
                  items: const [
                    DropdownMenuItem(value: 'System', child: Text('Sistema')),
                    DropdownMenuItem(value: 'Poppins', child: Text('Poppins')),
                    DropdownMenuItem(value: 'Inter', child: Text('Inter')),
                    DropdownMenuItem(value: 'Geist', child: Text('Geist')),
                    DropdownMenuItem(value: 'Manrope', child: Text('Manrope')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      brandVisuals.value = visuals.copyWith(fontFamily: v);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Logo e marca d’água'),
            subtitle: Text(
              visuals.logo == null
                  ? 'Usando o logo SysCredi'
                  : 'Logo institucional configurado',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }

  Widget _body() {
    if (route == 'settings' || route == 'organization-settings')
      return _settingsBody();
    if (route == 'clients') return _clientsBody();
    if (route == 'dashboard') return _dashboardBody();
    if (route == 'simulator' || route == 'reports') {
      final cards = Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (key, label) in [
            ('clients', 'Clientes activos'),
            ('pending_requests', 'Pedidos pendentes'),
            ('outstanding_cents', 'Saldo em dívida'),
            ('overdue_cents', 'Montante vencido'),
          ])
            SizedBox(
              width: 250,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label),
                      const SizedBox(height: 12),
                      Text(
                        key.endsWith('_cents')
                            ? money(metrics[key] ?? 0)
                            : '${metrics[key] ?? 0}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
      if (route == 'simulator') return cards;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cards,
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Estado da carteira',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveReport(
                      '/reports/portfolio.csv',
                      'estado_carteira.csv',
                      'text/csv',
                    ),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Gerar CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _saveReport(
                      '/reports/portfolio.pdf',
                      'estado_carteira.pdf',
                      'application/pdf',
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Gerar PDF'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Relatório mensal do Banco Central',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveReport(
                      '/reports/central-bank.csv',
                      'relatorio_mensal_banco_central.csv',
                      'text/csv',
                    ),
                    icon: const Icon(Icons.table_view_outlined),
                    label: const Text('Gerar CSV'),
                  ),
                  FilledButton.icon(
                    onPressed: () => _saveReport(
                      '/reports/central-bank.pdf',
                      'relatorio_mensal_banco_central.pdf',
                      'application/pdf',
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Gerar PDF'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (route == 'pending') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Operações enviadas sem confirmação definitiva. O reenvio mantém a mesma referência. Não registe outro pagamento para compensar uma resposta em falta.',
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhuma operação por confirmar.'),
              ),
            ),
          for (final operation in pending)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operação: ${operation.path.contains('payments')
                          ? 'Pagamento'
                          : operation.path.contains('disburse')
                          ? 'Desembolso'
                          : 'Actualização de registo'}',
                    ),
                    Text('Referência: ${operation.key}'),
                    if (operation.body['amountCents'] != null)
                      Text(money(operation.body['amountCents'])),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy ? null : () => retry(operation),
                      child: const Text('Consultar / reenviar'),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => cancelPending(operation),
                      child: const Text('Cancelar se ainda não executada'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    if (route == 'accounting-periods') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: busy ? null : _closeAccountingPeriod,
              icon: const Icon(Icons.lock_clock_outlined),
              label: const Text('Encerrar período'),
            ),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty && !loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum período encerrado.'),
              ),
            ),
          if (rows.isNotEmpty) _recordsTable(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rows.isEmpty && !loading)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhum registo encontrado.'),
            ),
          ),
        if (rows.isNotEmpty) _recordsTable(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                onPressed: offset > 0 && !loading
                    ? () {
                        offset -= 50;
                        load();
                      }
                    : null,
                child: const Text('Anterior'),
              ),
            ),
            Text('Página ${offset ~/ 50 + 1}'),
            Expanded(
              child: TextButton(
                onPressed: rows.length == 50 && !loading
                    ? () {
                        offset += 50;
                        load();
                      }
                    : null,
                child: const Text('Seguinte'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _recordsTable() {
    final columns = <String>{};
    for (final row in rows) {
      for (final key in row.keys) {
        if (![
          'organization_id',
          'organizationId',
          'version',
          'updated_at',
        ].contains(key)) {
          columns.add(key);
        }
      }
    }
    final preferred = [
      'name',
      'client_name',
      'legal_name',
      'trading_name',
      'document',
      'stage',
      'status',
      'amount_cents',
      'balance_cents',
      'role',
      'created_at',
    ];
    final fields = [
      ...preferred.where(columns.contains),
      ...columns.where((key) => !preferred.contains(key)).take(2),
    ].take(5).toList();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dataRowMinHeight: 56,
          dataRowMaxHeight: 72,
          headingRowHeight: 52,
          horizontalMargin: 20,
          columnSpacing: 28,
          columns: [
            for (final field in fields)
              DataColumn(label: Text((_labels[field] ?? field).toUpperCase())),
            const DataColumn(label: Text('ACÇÕES')),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final field in fields)
                    DataCell(
                      Text(
                        display(field, row[field]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DataCell(
                    PopupMenuButton<String>(
                      onSelected: (value) => _runRowAction(value, row),
                      itemBuilder: (_) => _rowActions(row),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _rowActions(Json row) => [
    const PopupMenuItem(value: 'details', child: Text('Detalhes')),
    if (route == 'businesses')
      const PopupMenuItem(value: 'business', child: Text('Editar')),
    if (route == 'co-signers')
      const PopupMenuItem(value: 'co-signer', child: Text('Editar')),
    if (route == 'requests' &&
        widget.session.analyst &&
        ['documentation', 'analysis', 'committee'].contains(row['stage']))
      const PopupMenuItem(value: 'decide', child: Text('Decidir')),
    if (route == 'requests' &&
        widget.session.manager &&
        row['stage'] == 'approved')
      const PopupMenuItem(value: 'disburse', child: Text('Desembolsar')),
    if (route == 'loans') ...[
      const PopupMenuItem(
        value: 'schedule',
        child: Text('Plano de prestações'),
      ),
      if (intValue(row['balance_cents']) > 0)
        const PopupMenuItem(value: 'pay', child: Text('Receber pagamento')),
    ],
    if (route == 'payments' && widget.session.manager)
      const PopupMenuItem(value: 'reverse', child: Text('Estornar pagamento')),
    if (route == 'users' && widget.session.manager)
      const PopupMenuItem(value: 'user', child: Text('Gerir acesso')),
    if (route == 'receipts')
      const PopupMenuItem(value: 'copy', child: Text('Copiar recibo')),
  ];

  Future<void> _runRowAction(String value, Json row) async {
    switch (value) {
      case 'details':
        await details(row);
      case 'business':
        await editBusiness(row);
      case 'co-signer':
        await editCoSigner(row);
      case 'decide':
        await decide(row);
      case 'disburse':
        await disburse(row);
      case 'schedule':
        await schedule(row);
      case 'pay':
        await pay(row);
      case 'reverse':
        await reversePayment(row);
      case 'user':
        await editUser(row);
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text:
                'SysCredi — Recibo ${row['id']}\nPagamento: ${row['payment_id']}\nMontante: ${money(row['amount_cents'])}\nEmitido: ${row['created_at']}',
          ),
        );
    }
  }

  Future<void> selectOrganization() async {
    try {
      final raw = await api.get('/organizations/mine') as List;
      final organizations = raw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted || organizations.isEmpty) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Mudar organização'),
          children: [
            for (final organization in organizations)
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(dialogContext, '${organization['id']}'),
                child: Text(
                  '${organization['name']}${organization['id'] == widget.session.profile?['organizationId'] ? ' · actual' : ''}',
                ),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      await api.write('POST', '/organizations/select', {
        'organizationId': selected,
      });
      await widget.session.verify();
      if (mounted) {
        setState(() {
          route = 'dashboard';
          rows = [];
          metrics = {};
        });
        await load();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Widget _clientsBody() {
    final visible = rows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: clientCategory,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cliente',
                  prefixIcon: Icon(Icons.filter_alt_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Indivíduos',
                    child: Text('Indivíduos'),
                  ),
                  DropdownMenuItem(value: 'Empresas', child: Text('Empresas')),
                  DropdownMenuItem(
                    value: 'Avalistas',
                    child: Text('Avalistas'),
                  ),
                  DropdownMenuItem(
                    value: 'Co-assinantes',
                    child: Text('Co-assinantes'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => clientCategory = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            EqualButtonGroup(
              children: [
                OutlinedButton.icon(
                  onPressed: busy || loading ? null : importClients,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importar CSV'),
                ),
                FilledButton.icon(
                  onPressed: busy || loading ? null : create,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Novo cliente'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Nenhum cliente encontrado.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 68,
                    headingRowHeight: 52,
                    horizontalMargin: 20,
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(label: Text('CLIENTE')),
                      DataColumn(label: Text('DOCUMENTO')),
                      DataColumn(label: Text('ACTIVIDADE')),
                      DataColumn(label: Text('LOCALIZAÇÃO')),
                      DataColumn(label: Text('KYC')),
                      DataColumn(label: Text('ACÇÕES')),
                    ],
                    rows: [
                      for (final row in visible)
                        DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: green.withValues(
                                      alpha: .12,
                                    ),
                                    child: Text(
                                      '${row['name'] ?? '?'}'.trim().isEmpty
                                          ? '?'
                                          : '${row['name']}'
                                                .trim()[0]
                                                .toUpperCase(),
                                      style: const TextStyle(
                                        color: green,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${row['name'] ?? '—'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${row['phone'] ?? '—'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text('${row['document'] ?? '—'}')),
                            DataCell(Text('${row['activity'] ?? '—'}')),
                            DataCell(Text('${row['location'] ?? '—'}')),
                            DataCell(_kycBadge(row)),
                            DataCell(
                              PopupMenuButton<String>(
                                tooltip: 'Acções do cliente',
                                onSelected: (value) {
                                  if (value == 'view') {
                                    details(row, title: 'Resumo do cliente');
                                  }
                                  if (value == 'edit') editClient(row);
                                  if (value == 'kyc') kyc(row);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Text('Ver resumo'),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'kyc',
                                    child: Text('Rever identificação'),
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

  Widget _kycBadge(Json row) {
    final expired =
        row['kyc_expires_at'] != null &&
        DateTime.tryParse(
              '${row['kyc_expires_at']}',
            )?.isBefore(DateTime.now()) ==
            true;
    final label = expired
        ? 'Expirado'
        : row['kyc_expires_at'] == null
        ? 'Em revisão'
        : 'Verificado';
    final color = expired
        ? Colors.redAccent
        : label == 'Verificado'
        ? green
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Area _currentArea() => switch (route) {
    'simulator' => Area.simulator,
    'products' => Area.products,
    'clients' || 'businesses' || 'co-signers' => Area.clients,
    'requests' => Area.applications,
    'loans' || 'contracts' => Area.portfolio,
    'payments' || 'receipts' => Area.collections,
    'risk-scores' || 'aml-alerts' || 'field-visits' || 'documents' => Area.risk,
    'accounts' || 'account-transfers' => Area.accounts,
    'cash-entries' || 'reconciliations' || 'journal' => Area.treasury,
    'reports' => Area.reports,
    'audit' => Area.audit,
    'settings' || 'organization-settings' => Area.settings,
    _ => Area.dashboard,
  };

  String _routeForArea(Area area) => switch (area) {
    Area.simulator => 'simulator',
    Area.products => 'products',
    Area.clients => 'clients',
    Area.applications => 'requests',
    Area.portfolio => 'loans',
    Area.collections => 'payments',
    Area.risk => 'risk-scores',
    Area.accounts => 'accounts',
    Area.treasury => 'cash-entries',
    Area.reports => 'reports',
    Area.audit => 'audit',
    Area.settings => 'settings',
    _ => 'dashboard',
  };

  void _selectArea(Area area) => select(_routeForArea(area));

  void _selectSubmodule(String label) {
    if (label == 'Utilizadores') {
      select('users');
      return;
    }
    if (label == 'Indivíduos') clientCategory = label;
    if (label == 'Empresas') clientCategory = label;
    if (label == 'Avalistas') clientCategory = label;
    if (label == 'Co-assinantes') clientCategory = label;
    if (label == 'Estornos') {
      select('payment-reversals');
      return;
    }
    if ({
      'Indivíduos',
      'Empresas',
      'Avalistas',
      'Co-assinantes',
    }.contains(label)) {
      select('clients');
      return;
    }
    if (label == 'Conciliação bancária') {
      select('reconciliations');
      return;
    }
    if (label == 'Movimentos de caixa') {
      select('cash-entries');
      return;
    }
    select('reports');
  }

  String _pageTitle() => sections
      .firstWhere(
        (section) => section.path == route,
        orElse: () =>
            const _Section('dashboard', 'Início', Icons.home_outlined),
      )
      .title;

  Future<void> _openSearch() async {
    if (busy) return;
    final selection = await showDialog<SearchSelection>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .3),
      builder: (_) => WorkspaceSearchDialog(
        repository: api,
        destinations: [
          for (final section in sections)
            (path: section.path, title: section.title, icon: section.icon),
        ],
      ),
    );
    if (!mounted || selection == null || busy) return;
    setState(() {
      route = selection.path;
      offset = 0;
      rows = [];
      metrics = {};
      pending = [];
      updated = null;
      search.text = selection.query;
    });
    await load();
  }

  Widget _navbarAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    int badge = 0,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (badge > 0)
          Positioned(
            right: -7,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      drawer: wide
          ? null
          : Drawer(
              child: SideBar(
                area: _currentArea(),
                onTap: _selectArea,
                onSubmenu: _selectSubmodule,
              ),
            ),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                SideBar(
                  area: _currentArea(),
                  onTap: _selectArea,
                  onSubmenu: _selectSubmodule,
                ),
              Expanded(
                child: Column(
                  children: [
                    AppBar(
                      automaticallyImplyLeading: !wide,
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (route != 'dashboard')
                            IconButton(
                              tooltip: 'Voltar para Início',
                              visualDensity: VisualDensity.compact,
                              onPressed: busy
                                  ? null
                                  : () => select('dashboard'),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          Flexible(
                            child: Text(
                              _pageTitle(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      centerTitle: false,
                      toolbarHeight: 64,
                      titleSpacing: wide ? 24 : 8,
                      actions: [
                        _navbarAction(
                          tooltip: 'Pesquisar',
                          icon: Icons.search_rounded,
                          onPressed: _openSearch,
                        ),
                        _navbarAction(
                          tooltip: 'Pendências',
                          icon: Icons.hourglass_empty_rounded,
                          badge: pending.length,
                          onPressed: () => select('pending'),
                        ),
                        _navbarAction(
                          tooltip: 'Alertas',
                          icon: Icons.notifications_outlined,
                          badge: metrics['overdue_cents'] == null ? 0 : 6,
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Não existem novas notificações.',
                                  ),
                                ),
                              ),
                        ),
                        _navbarAction(
                          tooltip: 'Cobranças e tesouraria',
                          icon: Icons.attach_money_rounded,
                          badge: metrics['overdue_cents'] == null ? 0 : 0,
                          onPressed: () => select('payments'),
                        ),
                        IconButton(
                          tooltip: 'Tema',
                          onPressed: () async {
                            final selected = await showDialog<ThemeMode>(
                              context: context,
                              builder: (dialogContext) => SimpleDialog(
                                title: const Text('Tema da aplicação'),
                                children: [
                                  for (final option in [
                                    (
                                      ThemeMode.system,
                                      'Automático',
                                      Icons.brightness_auto_outlined,
                                    ),
                                    (
                                      ThemeMode.light,
                                      'Claro',
                                      Icons.light_mode_outlined,
                                    ),
                                    (
                                      ThemeMode.dark,
                                      'Escuro',
                                      Icons.dark_mode_outlined,
                                    ),
                                  ])
                                    SimpleDialogOption(
                                      onPressed: () => Navigator.pop(
                                        dialogContext,
                                        option.$1,
                                      ),
                                      child: ListTile(
                                        leading: Icon(option.$3),
                                        title: Text(option.$2),
                                      ),
                                    ),
                                ],
                              ),
                            );
                            if (selected != null)
                              widget.onTheme?.call(selected);
                          },
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.dark_mode_outlined
                                : Icons.light_mode_outlined,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Definições',
                          onPressed: busy ? null : () => select('settings'),
                          icon: const Icon(fluent.FluentIcons.settings),
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          tooltip: 'Conta',
                          icon: const Icon(Icons.account_circle_outlined),
                          onSelected: (value) async {
                            if (value == 'logout')
                              await widget.session.logout();
                            if (value == 'organization')
                              await selectOrganization();
                            if (value == 'profile' && context.mounted) {
                              final profile = widget.session.profile ?? {};
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Perfil de acesso'),
                                  content: Text(
                                    'Nome: ${profile['name'] ?? '—'}\nPerfil: ${_roles[profile['role']] ?? profile['role'] ?? '—'}\nOrganização: ${profile['organization_id'] ?? profile['organizationId'] ?? '—'}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem<String>(
                              enabled: false,
                              child: Text(
                                '${widget.session.profile?['name']}\n${_roles[widget.session.profile?['role']] ?? ''}',
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'profile',
                              child: Text('Ver perfil'),
                            ),
                            const PopupMenuItem(
                              value: 'organization',
                              child: Text('Mudar organização'),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Text('Terminar sessão'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (loading || busy) const LinearProgressIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EqualButtonGroup(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                if (route == 'clients')
                                  OutlinedButton.icon(
                                    onPressed: busy || loading
                                        ? null
                                        : importClients,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Importar CSV'),
                                  ),
                                if (canCreate)
                                  FilledButton.icon(
                                    onPressed: busy || loading ? null : create,
                                    icon: const Icon(Icons.add),
                                    label: Text(
                                      route == 'users'
                                          ? 'Autorizar utilizador'
                                          : 'Novo registo',
                                    ),
                                  ),
                              ],
                            ),
                            if (![
                              'dashboard',
                              'simulator',
                              'reports',
                              'pending',
                            ].contains(route))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: TextField(
                                  controller: search,
                                  decoration: InputDecoration(
                                    labelText: 'Pesquisar',
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        offset = 0;
                                        load();
                                      },
                                      icon: const Icon(Icons.search),
                                    ),
                                  ),
                                  onSubmitted: (_) {
                                    offset = 0;
                                    load();
                                  },
                                ),
                              ),
                            const SizedBox(height: 20),
                            _body(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const BrandWatermarkOverlay(),
        ],
      ),
    );
  }
}
