import 'dart:async';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syscredi/core/widgets/equal_button_group.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/csv/csv_codec.dart';
import '../domain/money.dart';
import '../domain/repository.dart';
import 'form.dart';
import 'navigation.dart';
import 'search_dialog.dart';
import 'session_view_model.dart';
import 'simulator_panel.dart';
import 'credit_stages.dart';
import 'portfolio_views.dart';
import 'report_views.dart';
import 'credit_products.dart';
import 'finance_views.dart';
import 'admin_views.dart';
import 'plans_view.dart';
import 'audit_logs_view.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/institution_settings_view.dart';
import '../../settings/presentation/institution_branding.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../../core/widgets/operation_feedback.dart';
import 'risk_center_view.dart';

const _stages = {
  'documentation': 'Documentação',
  'analysis': 'Análise',
  'committee': 'Comité',
  'approved': 'Aprovado',
  'rejected': 'Recusado',
  'disbursed': 'Desembolsado',
};
const _creditStageRoutes = {
  'financing',
  'financial-analysis',
  'credit-approval',
  'credit-authorization',
  'credit-disbursement',
  'credit-status',
  'credit-restructuring',
};
const _reportKinds = <String, String>{
  'report-pdf': 'Em PDF',
  'report-excel': 'Em Excel',
  'report-records': 'Registos',
  'report-letters': 'Cartas',
  'report-monthly-bm': 'Mensal para BM',
  'report-quarterly-bm': 'Trimestral para BM',
  'report-credits': 'Créditos',
  'report-clients': 'Clientes',
  'report-financial': 'Financeiros',
  'report-misc': 'Diversos',
};
const _financeAreas = <String, String>{
  'finance-balances': 'Saldos',
  'finance-reversals': 'Estornos',
  'finance-income': 'Receitas',
  'finance-expenses': 'Despesas',
  'finance-disbursements': 'Desembolsos',
  'finance-refunds': 'Reembolsos',
  'finance-overdue': 'Prestações Vencidas',
  'finance-assets': 'Ativos',
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
      child: AnimatedContainer(
        duration: FluentTokens.fast,
        curve: FluentTokens.curve,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hovered
                ? border.withValues(alpha: .72)
                : Color.lerp(scheme.outlineVariant, border, .14)!,
            width: hovered ? 1.35 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: hovered ? .16 : .09),
              blurRadius: hovered ? 18 : 10,
              offset: Offset(0, hovered ? 6 : 3),
            ),
            if (hovered)
              BoxShadow(
                color: border.withValues(alpha: .08),
                blurRadius: 2,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

class _DashboardDonutPainter extends CustomPainter {
  _DashboardDonutPainter(this.primary, this.secondary);
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final track = Paint()
      ..color = primary.withValues(alpha: .10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    final first = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final second = Paint()
      ..color = secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 1.55,
      false,
      first,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.05,
      math.pi * .55,
      false,
      second,
    );
  }

  @override
  bool shouldRepaint(covariant _DashboardDonutPainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

class Workspace extends StatefulWidget {
  const Workspace({required this.session, this.onTheme, super.key});
  final WorkspaceSession session;
  final ValueChanged<ThemeMode>? onTheme;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  Future<void> _feedback(
    String message, {
    String title = 'Informação',
    bool? success,
  }) => showFeedbackDialog(
    context,
    title: title,
    message: message,
    success: success,
  );
  String get _institutionName =>
      (institutionBranding.value['tradeName'] ?? 'SysCredi')
          .toString()
          .trim()
          .isEmpty
      ? 'SysCredi'
      : '${institutionBranding.value['tradeName']}';
  late final InstitutionSettingsController institutionSettings;
  final institutionSettingsKey = GlobalKey<InstitutionSettingsViewState>();
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
    const _Section(
      'financing',
      'Financiamento',
      Icons.assignment_turned_in_outlined,
    ),
    const _Section(
      'financial-analysis',
      'Análise financeira',
      Icons.analytics_outlined,
    ),
    const _Section('credit-approval', 'Aprovar crédito', Icons.check),
    const _Section(
      'credit-authorization',
      'Autorizar crédito',
      Icons.assignment_turned_in_outlined,
    ),
    const _Section(
      'credit-disbursement',
      'Desembolso',
      Icons.payments_outlined,
    ),
    const _Section(
      'credit-status',
      'Estado do crédito',
      Icons.analytics_outlined,
    ),
    const _Section(
      'credit-restructuring',
      'Reestruturação de crédito',
      Icons.swap_horiz_outlined,
    ),
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
  String clientStatusFilter = 'Todos';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    institutionSettings = InstitutionSettingsController(
      scope:
          '${widget.session.profile?['organization_id'] ?? widget.session.profile?['id'] ?? 'demo'}',
      actor: '${widget.session.profile?['name'] ?? 'Gestor'}',
    );
    institutionSettings.load().then((_) {
      if (mounted && institutionSettings.error == null)
        applyInstitutionSettings(institutionSettings.saved);
    });
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
    institutionSettings.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    final current = ++generation, target = route;
    setState(() {
      loading = true;
      error = null;
    });
    if (_creditStageRoutes.contains(target) ||
        target == 'settings' ||
        target == 'organization-settings') {
      if (mounted && current == generation) setState(() => loading = false);
      return;
    }
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

  Future<void> select(String next) async {
    if (busy) return;
    if ((route == 'settings' || route == 'organization-settings') &&
        next != route) {
      final state = institutionSettingsKey.currentState;
      if (state != null && !await state.requestLeave()) return;
      if (!mounted) return;
    }
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
        await _feedback(
          'Operação confirmada no servidor.',
          title: 'Operação confirmada',
          success: true,
        );
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        await _feedback(
          e.message,
          title: 'Operação não confirmada',
          success: false,
        );
      }
    } catch (_) {
      if (mounted) {
        await _feedback(
          'Não foi possível confirmar. Consulte Pendências antes de repetir.',
          title: 'Operação não confirmada',
          success: false,
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
        Field('entityType', 'Tipo de entidade', optional: true),
        Field('licenseNumber', 'Número da licença', optional: true),
        Field('phone', 'Telefone'),
        Field('email', 'Email', optional: true),
        Field('address', 'Endereço'),
        Field('city', 'Cidade', optional: true),
        Field('activity', 'Actividade'),
        Field('representative', 'Representante'),
        Field('politicallyExposed', 'Politicamente exposta?', optional: true),
        Field('notify', 'Notificar?', optional: true),
        Field('receiveNotifications', 'Receber notificações?', optional: true),
        Field('location', 'Localização GPS', optional: true),
      ],
      'co-signers' => const [
        Field('clientId', 'Cliente', resource: 'clients'),
        Field('name', 'Nome'),
        Field('document', 'Documento'),
        Field('phone', 'Telefone'),
        Field('gender', 'Género', optional: true),
        Field('birthDate', 'Data de nascimento', kind: 'date', optional: true),
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
        Field('gender', 'Género', optional: true),
        Field('birthDate', 'Data de nascimento', kind: 'date', optional: true),
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
      route == 'users'
          ? 'Autorizar utilizador existente'
          : route == 'clients'
          ? 'Novo indivíduo'
          : route == 'businesses'
          ? 'Nova empresa'
          : 'Novo registo',
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
        await _feedback(
          'CSV importado no servidor.',
          title: 'Importação concluída',
          success: true,
        );
      }
      await load();
    } catch (e) {
      if (mounted) {
        await _feedback(
          '$e',
          title: 'Importação não concluída',
          success: false,
        );
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
      // O cadastro de empresa possui fluxo e formulário próprios.
      options: const {'individual': 'Indivíduo'},
      initial: 'individual',
    ),
    Field('name', 'Nome completo', initial: row?['name']?.toString() ?? ''),
    Field(
      'email',
      'Email',
      optional: true,
      initial: row?['email']?.toString() ?? '',
    ),
    Field('phone', 'Telefone', initial: row?['phone']?.toString() ?? ''),
    Field(
      'documentType',
      'Tipo de documento',
      optional: true,
      initial: row?['document_type']?.toString() ?? '',
    ),
    Field(
      'documentExpiry',
      'Validade do documento',
      kind: 'date',
      optional: true,
      initial: row?['document_expiry']?.toString() ?? '',
    ),
    Field(
      'document',
      'Número do documento',
      initial: row?['document']?.toString() ?? '',
    ),
    Field(
      'issuePlace',
      'Local de emissão',
      optional: true,
      initial: row?['issue_place']?.toString() ?? '',
    ),
    Field(
      'birthDate',
      'Data de nascimento',
      kind: 'date',
      optional: true,
      initial: row?['birth_date']?.toString() ?? '',
    ),
    Field(
      'nationality',
      'Nacionalidade',
      optional: true,
      initial: row?['nationality']?.toString() ?? '',
    ),
    Field(
      'street',
      'Rua',
      optional: true,
      initial: row?['street']?.toString() ?? '',
    ),
    Field(
      'neighborhood',
      'Bairro',
      optional: true,
      initial: row?['neighborhood']?.toString() ?? '',
    ),
    Field(
      'houseNumber',
      'Número da casa',
      optional: true,
      initial: row?['house_number']?.toString() ?? '',
    ),
    Field(
      'quarter',
      'Quarteirão',
      optional: true,
      initial: row?['quarter']?.toString() ?? '',
    ),
    Field(
      'city',
      'Cidade',
      optional: true,
      initial: row?['city']?.toString() ?? '',
    ),
    Field(
      'maritalStatus',
      'Estado civil',
      optional: true,
      initial: row?['marital_status']?.toString() ?? '',
    ),
    Field(
      'politicallyExposed',
      'Politicamente exposto?',
      optional: true,
      initial: row?['politically_exposed']?.toString() ?? '',
    ),
    Field(
      'registrationDate',
      'Data de cadastro',
      kind: 'date',
      optional: true,
      initial: row?['registration_date']?.toString() ?? '',
    ),
    Field(
      'gender',
      'Género',
      optional: true,
      initial: row?['gender']?.toString() ?? '',
    ),
    Field(
      'status',
      'Situação',
      optional: true,
      initial: row?['status']?.toString() ?? '',
    ),
    Field(
      'notify',
      'Notificar?',
      optional: true,
      initial: row?['notify']?.toString() ?? '',
    ),
    Field(
      'receiveNotifications',
      'Receber notificações?',
      optional: true,
      initial: row?['receive_notifications']?.toString() ?? '',
    ),
    Field(
      'photo',
      'Foto do cliente',
      optional: true,
      initial: row?['photo']?.toString() ?? '',
    ),
    Field(
      'location',
      'Localização GPS',
      optional: true,
      initial: row?['location']?.toString() ?? '',
    ),
    Field(
      'observations',
      'Observações',
      optional: true,
      initial: row?['observations']?.toString() ?? '',
    ),
    Field(
      'manager',
      'Gestor',
      optional: true,
      initial: row?['manager']?.toString() ?? '',
    ),
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
        initial: row['archived'] == true ? 'true' : 'false',
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
      Field(
        'entityType',
        'Tipo de entidade',
        optional: true,
        initial: '${row['entity_type'] ?? ''}',
      ),
      Field(
        'licenseNumber',
        'Número da licença',
        optional: true,
        initial: '${row['license_number'] ?? ''}',
      ),
      Field('phone', 'Telefone', initial: '${row['phone'] ?? ''}'),
      Field('email', 'Email', optional: true, initial: '${row['email'] ?? ''}'),
      Field('address', 'Endereço', initial: '${row['address'] ?? ''}'),
      Field('city', 'Cidade', optional: true, initial: '${row['city'] ?? ''}'),
      Field('activity', 'Actividade', initial: '${row['activity'] ?? ''}'),
      Field(
        'representative',
        'Representante',
        initial: '${row['representative'] ?? ''}',
      ),
      Field(
        'politicallyExposed',
        'Politicamente exposta?',
        optional: true,
        initial: '${row['politically_exposed'] ?? ''}',
      ),
      Field(
        'notify',
        'Notificar?',
        optional: true,
        initial: '${row['notify'] ?? ''}',
      ),
      Field(
        'receiveNotifications',
        'Receber notificações?',
        optional: true,
        initial: '${row['receive_notifications'] ?? ''}',
      ),
      Field(
        'location',
        'Localização GPS',
        optional: true,
        initial: '${row['location'] ?? ''}',
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
        await _feedback('$e', title: 'Operação não concluída', success: false);
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

  Future<void> details(
    Json row, {
    String title = 'Detalhes',
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return PremiumDialog(
        title: Text(title),
        subtitle:
            '${row['name'] ?? row['legal_name'] ?? row['trading_name'] ?? 'Registo'} · ${row['id'] ?? ''}',
        icon: row['legal_name'] != null
            ? Icons.business_outlined
            : Icons.person,
        width: 900,
        content: DetailFields(
          fields: [
            for (final entry in row.entries.where(
              (e) => e.value is! Map && e.value is! List && e.key != 'id',
            ))
              (
                _labels[entry.key] ?? entry.key,
                display(entry.key, entry.value),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Concluir'),
          ),
        ],
      );
    },
  );
  Future<void> retry(PendingWrite operation) async {
    setState(() => busy = true);
    try {
      await api.retry(operation);
      if (mounted) {
        await _feedback(
          'Resultado confirmado. Actualize a carteira para consultar o saldo.',
          title: 'Resultado confirmado',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) {
        await _feedback('$e', title: 'Operação não concluída', success: false);
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
        await _feedback(
          status == 'confirmed'
              ? 'A operação já foi concluída. Consulte os dados actualizados.'
              : 'Cancelamento confirmado. A operação não será executada.',
          title: 'Operação cancelada',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) {
        await _feedback(
          '$e',
          title: 'Cancelamento não concluído',
          success: false,
        );
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
              mainAxisExtent: viewport.maxWidth < 540 ? 160 : 154,
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
                  Icons.assignment_turned_in_outlined,
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
    final pending = SizedBox(
      height: 360,
      child: _projectionCard('Projecção pendente', scheme.error, [
        ('Capital a ser devolvido', '296.840,00 MZN', .77),
        ('Juros a ser devolvido', '87.152,00 MZN', .23),
        ('Mora a ser paga', '0,00 MZN', .04),
        ('Total a ser pago', '383.992,00 MZN', 1),
      ]),
    );
    final paid = SizedBox(
      height: 360,
      child: _projectionCard('Projecção paga', scheme.secondary, [
        ('Capital pago', '33.101,40 MZN', .52),
        ('Juros pago', '26.764,95 MZN', .42),
        ('Mora paga', '3.959,65 MZN', .06),
        ('Multa paga', '0,00 MZN', .01),
        ('Total pago', '63.826,00 MZN', 1),
      ]),
    );
    if (width < 900) {
      return Column(children: [pending, const SizedBox(height: 18), paid]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: pending),
        const SizedBox(width: 18),
        Expanded(child: paid),
      ],
    );
  }

  Widget _projectionCard(
    String title,
    Color color,
    List<(String, String, double)> values,
  ) => _surface(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    title.contains('paga')
                        ? Icons.check_circle_outline
                        : Icons.history,
                    size: 13,
                    color: color,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    title.contains('paga') ? 'Liquidado' : 'Em aberto',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                    value: value.$3,
                    minHeight: value.$1.startsWith('Total') ? 8 : 6,
                    backgroundColor: color.withValues(alpha: .10),
                    valueColor: AlwaysStoppedAnimation(color),
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
    final cardWidth = width >= 1150
        ? 350.0
        : width >= 730
        ? 350.0
        : width;
    Widget fixed(Widget child) =>
        SizedBox(width: cardWidth, height: 360, child: child);
    return Wrap(
      spacing: 18,
      runSpacing: 18,
      children: [
        fixed(_riskPanel()),
        fixed(
          _listPanel('Reembolso mensal', [
            ('Júlio Custódio', '900,00 MZN'),
            ('Silvério João Muaquiqua', '3.250,00 MZN'),
            ('Francisco Adelino Rui', '3.250,00 MZN'),
            ('Agostinho Querino', '5.200,00 MZN'),
          ], scheme.secondary),
        ),
        fixed(
          _listPanel('Desembolso mensal', [
            ('Pascoal João Muaquiquia', '3.000,00 MZN'),
            ('Armando Manuel António', '5.000,00 MZN'),
            ('Júlio Custódio', '2.500,00 MZN'),
            ('Edson Mário Morais', '1.000,00 MZN'),
          ], scheme.error),
        ),
        fixed(
          _listPanel('Gestão de logs', [
            ('Naveia Muaquiquia João', 'login'),
            ('Naveia Muaquiquia João', 'logout'),
            ('Loide Janeth Ligia', 'submissão'),
            ('Loide Janeth Ligia', 'login'),
          ], scheme.primary),
        ),
        fixed(
          _distributionPanel(
            'Distribuição das contas',
            Icons.bar_chart_rounded,
          ),
        ),
        fixed(
          _distributionPanel(
            'Distribuição dos clientes',
            Icons.pie_chart_outline_rounded,
          ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shield, size: 14, color: scheme.tertiary),
                const SizedBox(width: 6),
                Text(
                  '6 faixas monitorizadas',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: CustomPaint(
                  painter: _DashboardDonutPainter(
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _distributionLegend(
                      'Masculino',
                      '79,8%',
                      Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _distributionLegend(
                      'Feminino',
                      '17,2%',
                      Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(height: 12),
                    _distributionLegend(
                      'Outro',
                      '3,0%',
                      Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _distributionLegend(String label, String value, Color color) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ],
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
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: accent, size: 18),
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
        await _feedback(
          'Relatório guardado em ${location.path}',
          title: 'Relatório guardado',
          success: true,
        );
      }
    } catch (e) {
      if (mounted) {
        await _feedback(
          'Não foi possível gerar o relatório: $e',
          title: 'Relatório não gerado',
          success: false,
        );
      }
    }
  }

  Widget _body() {
    if (route == 'risk-scores') {
      if (error != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Não foi possível carregar a Central de risco.'),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: loading ? null : load,
              child: const Text('Tentar novamente'),
            ),
          ],
        );
      }
      if (loading && rows.isEmpty)
        return const Center(child: Text('A carregar avaliações de risco…'));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RiskCenterView(rows: rows),
          if (offset > 0 || rows.length == 50)
            Wrap(
              spacing: 12,
              children: [
                OutlinedButton(
                  onPressed: !loading && offset > 0
                      ? () {
                          offset -= 50;
                          load();
                        }
                      : null,
                  child: const Text('Registos anteriores'),
                ),
                OutlinedButton(
                  onPressed: !loading && rows.length == 50
                      ? () {
                          offset += 50;
                          load();
                        }
                      : null,
                  child: const Text('Próximos registos'),
                ),
              ],
            ),
        ],
      );
    }
    if (route == 'audit') {
      return Column(
        children: [
          AuditLogsView(rows: rows),
          if (offset > 0 || rows.length == 50)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: !loading && offset > 0
                        ? () {
                            offset -= 50;
                            load();
                          }
                        : null,
                    child: const Text('50 registos anteriores'),
                  ),
                  OutlinedButton(
                    onPressed: !loading && rows.length == 50
                        ? () {
                            offset += 50;
                            load();
                          }
                        : null,
                    child: const Text('Carregar próximos registos'),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    if (route == 'credit-portfolio' ||
        route == 'loans' ||
        route == 'contracts' ||
        route == 'portfolio') {
      return const PortfolioView();
    }
    if (route == 'collections' || route == 'payments' || route == 'receipts') {
      return const CollectionsView();
    }
    if (route == 'products') return const CreditProductsView();
    if (route.startsWith('finance-'))
      return FinanceView(
        key: ValueKey(route),
        area: _financeAreas[route] ?? 'Saldos',
      );
    if (route.startsWith('report-')) {
      return ReportView(kind: _reportKinds[route] ?? 'Créditos');
    }
    if (route.startsWith('admin-')) {
      return AdminView(kind: route.substring(6), key: ValueKey(route));
    }
    if (route == 'plans') return const PlansView();
    if (_creditStageRoutes.contains(route)) {
      return CreditStagesView(stage: route);
    }
    if (route == 'settings' || route == 'organization-settings') {
      return InstitutionSettingsView(
        key: institutionSettingsKey,
        controller: institutionSettings,
        canAdminister: widget.session.manager,
      );
    }
    if ({
      'clients',
      'businesses',
      'co-signers',
      'client-guarantors',
    }.contains(route)) {
      return _clientsBody();
    }
    if (route == 'dashboard') return _dashboardBody();
    if (route == 'simulator') return const SimulatorPanel();
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
                '$_institutionName — Recibo ${row['id']}\nPagamento: ${row['payment_id']}\nMontante: ${money(row['amount_cents'])}\nEmitido: ${row['created_at']}',
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
        await _feedback(
          '$error',
          title: 'Operação não concluída',
          success: false,
        );
      }
    }
  }

  static final _mockIndividualClients = <Json>[
    {
      'id': 'mock-client-001',
      'name': 'Edson Mário Morais',
      'phone': '878 935 415',
      'document': '110105200085-C',
      'activity': 'Comércio a retalho',
      'location': 'Maputo · KaMpfumo',
      'gender': 'Masculino',
      'status': 'Regular',
      'kyc_expires_at': '2026-10-20',
      'registration_date': '2026-09-09',
      'city': 'Maputo',
      'nationality': 'Moçambicana',
      'birth_date': '1999-07-28',
      'marital_status': 'Solteiro(a)',
      'manager': 'Naveia Muaquiquia João',
    },
    {
      'id': 'mock-client-002',
      'name': 'Edilson Pereira Langa',
      'phone': '855 336 109',
      'document': '110108869332-P',
      'activity': 'Agricultura',
      'location': 'Maputo · Marracuene',
      'status': 'Regular',
      'kyc_expires_at': '2026-10-20',
      'registration_date': '2026-09-09',
    },
    {
      'id': 'mock-client-003',
      'name': 'Mucuaro Fernando',
      'phone': '870 000 335',
      'document': '031707123481-F',
      'activity': 'Serviços',
      'location': 'Maputo · Matola',
      'status': 'Regular',
      'kyc_expires_at': '2026-11-02',
      'registration_date': '2026-09-09',
    },
    {
      'id': 'mock-client-004',
      'name': 'Neves João Madeira',
      'phone': '876 608 410',
      'document': '110104093182-B',
      'activity': 'Comércio',
      'location': 'Maputo · KaMubukwana',
      'status': 'Regular',
      'kyc_expires_at': '2026-12-02',
      'registration_date': '2026-09-07',
    },
    {
      'id': 'mock-client-005',
      'name': 'Wezimane João Alficha',
      'phone': '878 935 415',
      'document': '060102696230-B',
      'activity': 'Produção',
      'location': 'Matola',
      'status': 'Regular',
      'registration_date': '2026-09-07',
    },
  ];

  static final _mockBusinesses = <Json>[
    {
      'id': 'mock-business-001',
      'legal_name': 'Ac esa Microcrédito, E.I',
      'trading_name': 'Acesa Microcrédito',
      'tax_number': '400123456',
      'phone': '823 456 789',
      'active': true,
      'city': 'Maputo',
      'entity_type': 'Sociedade limitada',
      'license_number': 'LIC-2026-0081',
      'activity': 'Serviços financeiros',
      'registration_date': '2026-09-09',
    },
  ];

  static final _mockGuarantors = <Json>[
    {
      'id': 'mock-guarantor-001',
      'name': 'Muaquiquia João',
      'phone': '869 198 551',
      'document': '040501882771J',
      'gender': 'Masculino',
      'relationship': 'Familiar',
      'birth_date': '1988-04-12',
      'registration_date': '2026-05-27',
    },
  ];

  Widget _clientsBody() {
    if (route != 'clients') return _relatedClientsBody();
    final source = rows.isEmpty ? _mockIndividualClients : rows;
    final visible = clientStatusFilter == 'Todos'
        ? source
        : source
              .where(
                (row) => '${row['status'] ?? 'Regular'}' == clientStatusFilter,
              )
              .toList();
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
                  _selectClientCategory(value);
                },
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: clientStatusFilter,
                decoration: InputDecoration(
                  labelText: 'Filtrar por status',
                  prefixIcon: const Icon(Icons.filter_alt_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'Bom', child: Text('Bom')),
                  DropdownMenuItem(value: 'Risco', child: Text('Risco')),
                  DropdownMenuItem(value: 'Péssimo', child: Text('Péssimo')),
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => clientStatusFilter = value);
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
                      DataColumn(label: Text('NOME')),
                      DataColumn(label: Text('TELEFONE')),
                      DataColumn(label: Text('NUMERO DOC')),
                      DataColumn(label: Text('SITUAÇÃO')),
                      DataColumn(label: Text('DATA CADASTRO')),
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text('${row['phone'] ?? '—'}')),
                            DataCell(Text('${row['document'] ?? '—'}')),
                            DataCell(_clientStatusBadge(row)),
                            DataCell(
                              Text(
                                '${row['registration_date'] ?? row['created_at'] ?? '—'}',
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _tableActionButton(
                                    tooltip: 'Ver resumo',
                                    icon: Icons.visibility_outlined,
                                    onPressed: () => details(
                                      row,
                                      title: 'Resumo do cliente',
                                    ),
                                  ),
                                  _tableActionButton(
                                    tooltip: 'Editar cliente',
                                    icon: Icons.edit,
                                    onPressed: () => editClient(row),
                                  ),
                                  _tableActionButton(
                                    tooltip: 'Rever identificação',
                                    icon: Icons.verified_outlined,
                                    onPressed: () => kyc(row),
                                  ),
                                  _tableActionButton(
                                    tooltip: 'Contratos e documentos',
                                    icon: Icons.receipt_long_outlined,
                                    onPressed: () => _clientDocuments(row),
                                  ),
                                  _tableActionButton(
                                    tooltip: 'Remover cliente',
                                    icon: Icons.delete_sweep_outlined,
                                    destructive: true,
                                    onPressed: () => _removeClientRecord(row),
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

  Widget _relatedClientsBody() {
    final company = route == 'businesses';
    final guarantor = route == 'client-guarantors';
    final coSigner = route == 'co-signers';
    final title = company
        ? 'Empresas'
        : guarantor
        ? 'Avalistas'
        : coSigner
        ? 'Co-assinantes'
        : 'Clientes';
    final visible = rows.isEmpty
        ? (company ? _mockBusinesses : _mockGuarantors)
        : rows;
    final columns = company
        ? const [
            ('legal_name', 'DENOMINAÇÃO LEGAL'),
            ('entity_type', 'TIPO'),
            ('tax_number', 'NUIT'),
            ('activity', 'ACTIVIDADE'),
            ('phone', 'TELEFONE'),
            ('city', 'CIDADE'),
            ('active', 'ESTADO'),
          ]
        : guarantor
        ? const [
            ('name', 'NOME'),
            ('phone', 'TELEFONE'),
            ('document', 'DOCUMENTO'),
            ('gender', 'GÉNERO'),
            ('registration_date', 'DATA CADASTRO'),
          ]
        : const [
            ('name', 'NOME'),
            ('document', 'DOCUMENTO'),
            ('phone', 'TELEFONE'),
            ('relationship', 'RELAÇÃO'),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: company
                    ? 'Empresas'
                    : guarantor
                    ? 'Avalistas'
                    : coSigner
                    ? 'Co-assinantes'
                    : 'Indivíduos',
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
                  if (value != null) _selectClientCategory(value);
                },
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: busy || loading ? null : create,
                icon: Icon(
                  company ? Icons.business_outlined : Icons.person_add,
                ),
                label: Text(
                  company
                      ? 'Adicionar empresa'
                      : coSigner
                      ? 'Adicionar co-assinante'
                      : 'Adicionar avalista',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Nenhum registo de $title encontrado.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 68,
                    headingRowHeight: 52,
                    horizontalMargin: 20,
                    columnSpacing: 28,
                    columns: [
                      for (final column in columns)
                        DataColumn(label: Text(column.$2)),
                      const DataColumn(label: Text('ACÇÕES')),
                    ],
                    rows: [
                      for (final row in visible)
                        DataRow(
                          cells: [
                            for (final column in columns)
                              DataCell(
                                Text(
                                  column.$1 == 'active'
                                      ? (row[column.$1] == false
                                            ? 'Inactiva'
                                            : 'Activa')
                                      : '${row[column.$1] ?? '—'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _tableActionButton(
                                    tooltip: 'Ver resumo',
                                    icon: Icons.visibility_outlined,
                                    onPressed: () =>
                                        details(row, title: 'Resumo de $title'),
                                  ),
                                  _tableActionButton(
                                    tooltip: company
                                        ? 'Editar empresa'
                                        : 'Editar registo',
                                    icon: Icons.edit,
                                    onPressed: () {
                                      if (company) {
                                        editBusiness(row);
                                      } else {
                                        editCoSigner(row);
                                      }
                                    },
                                  ),
                                  _tableActionButton(
                                    tooltip: company
                                        ? 'Remover empresa'
                                        : 'Remover registo',
                                    icon: Icons.delete_sweep_outlined,
                                    destructive: true,
                                    onPressed: () => _removeClientRecord(
                                      row,
                                      resource: company
                                          ? 'businesses'
                                          : guarantor
                                          ? 'client-guarantors'
                                          : 'co-signers',
                                    ),
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

  Future<void> _clientDocuments(Json row) async {
    final name = '${row['name'] ?? 'Cliente'}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Documentos de $name'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _documentAction(
                dialogContext,
                'Contrato de crédito',
                'contrato.pdf',
              ),
              _documentAction(
                dialogContext,
                'Contrato de confissão de dívida',
                'contrato_confissao.pdf',
              ),
              _documentAction(
                dialogContext,
                'Contrato de garantia',
                'contrato_de_garantia.pdf',
              ),
              _documentAction(
                dialogContext,
                'Estado do crédito',
                'credito_estado.pdf',
              ),
              _documentAction(
                dialogContext,
                'Recibo de desembolso',
                'recibo_de_desembolso.pdf',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _documentAction(
    BuildContext dialogContext,
    String label,
    String filename,
  ) => ListTile(
    leading: const Icon(FluentSystemIcons.picture_as_pdf_outlined),
    title: Text(label),
    subtitle: Text(filename),
    trailing: const Icon(FluentSystemIcons.download),
    onTap: () {
      Navigator.pop(dialogContext);
      _downloadClientDocument(label, filename);
    },
  );

  Future<void> _downloadClientDocument(String title, String filename) async {
    try {
      final location = await getSaveLocation(suggestedName: filename);
      if (location == null) return;
      final document = pw.Document();
      final branding = InstitutionDocument();
      document.addPage(
        pw.MultiPage(
          pageTheme: branding.pageTheme(),
          header: branding.header,
          footer: branding.footer,
          build: (_) => [
            pw.SizedBox(height: 24),
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 18),
            pw.Text('Documento de demonstração'),
            branding.signature('Comprovativo'),
          ],
        ),
      );
      await XFile.fromData(
        await document.save(),
        mimeType: 'application/pdf',
      ).saveTo(location.path);
      if (mounted) {
        await _feedback(
          'PDF guardado em ${location.path}',
          title: 'PDF guardado',
          success: true,
        );
      }
    } catch (error) {
      if (mounted) {
        await _feedback(
          'Não foi possível guardar o PDF: $error',
          title: 'PDF não guardado',
          success: false,
        );
      }
    }
  }

  Future<void> _removeClientRecord(
    Json row, {
    String resource = 'clients',
  }) async {
    final name = '${row['name'] ?? row['legal_name'] ?? 'este registo'}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover registo?'),
        content: Text('Esta acção irá remover “$name”. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true && row['id'] != null && mounted) {
      await mutate('DELETE', '/$resource/${row['id']}', {});
    }
  }

  Widget _tableActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool destructive = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: .10),
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        ),
      ),
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

  Widget _clientStatusBadge(Json row) {
    final status = '${row['status'] ?? 'Regular'}';
    final normalized = status.toLowerCase();
    final color = normalized.contains('péss') || normalized.contains('risco')
        ? Colors.orange
        : normalized.contains('bom') || normalized.contains('regular')
        ? green
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
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
    'clients' ||
    'businesses' ||
    'co-signers' ||
    'client-guarantors' => Area.clients,
    'requests' => Area.applications,
    'financing' => Area.creditFinancing,
    'financial-analysis' => Area.financialAnalysis,
    'credit-approval' => Area.creditApproval,
    'credit-authorization' => Area.creditAuthorization,
    'credit-disbursement' => Area.creditDisbursement,
    'credit-status' => Area.creditStatus,
    'credit-restructuring' => Area.creditRestructuring,
    'credit-portfolio' ||
    'loans' ||
    'contracts' ||
    'portfolio' => Area.portfolio,
    'collections' || 'payments' || 'receipts' => Area.collections,
    'risk-scores' || 'aml-alerts' || 'field-visits' || 'documents' => Area.risk,
    'accounts' || 'account-transfers' => Area.accounts,
    'cash-entries' || 'reconciliations' || 'journal' => Area.treasury,
    'reports' => Area.reports,
    'audit' => Area.audit,
    'plans' => Area.plans,
    'settings' || 'organization-settings' => Area.settings,
    _ => Area.dashboard,
  };

  String _routeForArea(Area area) => switch (area) {
    Area.simulator => 'simulator',
    Area.products => 'products',
    Area.clients => 'clients',
    Area.applications => 'requests',
    Area.creditFinancing => 'financing',
    Area.financialAnalysis => 'financial-analysis',
    Area.creditApproval => 'credit-approval',
    Area.creditAuthorization => 'credit-authorization',
    Area.creditDisbursement => 'credit-disbursement',
    Area.creditStatus => 'credit-status',
    Area.creditRestructuring => 'credit-restructuring',
    Area.portfolio => 'credit-portfolio',
    Area.collections => 'collections',
    Area.risk => 'risk-scores',
    Area.accounts => 'accounts',
    Area.treasury => 'cash-entries',
    Area.reports => 'reports',
    Area.audit => 'audit',
    Area.settings => 'settings',
    Area.accounting => 'admin-accounting',
    Area.sync => 'admin-sync',
    Area.aml => 'admin-aml',
    Area.users => 'admin-users',
    Area.backup => 'admin-backup',
    Area.plans => 'plans',
    _ => 'dashboard',
  };

  void _selectArea(Area area) => select(_routeForArea(area));

  void _selectClientCategory(String value) {
    clientCategory = value;
    final target = switch (value) {
      'Empresas' => 'businesses',
      'Avalistas' => 'client-guarantors',
      'Co-assinantes' => 'co-signers',
      _ => 'clients',
    };
    select(target);
  }

  void _selectSubmodule(String label) {
    String? financeRoute;
    for (final entry in _financeAreas.entries) {
      if (entry.value == label) {
        financeRoute = entry.key;
        break;
      }
    }
    if (financeRoute != null) {
      select(financeRoute);
      return;
    }
    String? reportRoute;
    for (final entry in _reportKinds.entries) {
      if (entry.value == label) {
        reportRoute = entry.key;
        break;
      }
    }
    if (reportRoute != null) {
      select(reportRoute);
      return;
    }
    if (label == 'Utilizadores') {
      select('users');
      return;
    }
    if (label == 'Indivíduos' || label == 'Empresas' || label == 'Avalistas') {
      _selectClientCategory(label);
      return;
    }
    if (label == 'Co-assinantes') {
      clientCategory = label;
      select('co-signers');
      return;
    }
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

  Future<void> _showProfileDialog() async {
    final profile = widget.session.profile ?? <String, dynamic>{};
    final name = TextEditingController(text: '${profile['name'] ?? ''}');
    final email = TextEditingController(text: '${profile['email'] ?? ''}');
    final phone = TextEditingController(text: '${profile['phone'] ?? ''}');
    final organization =
        '${profile['organization_name'] ?? profile['organization'] ?? profile['organization_id'] ?? profile['organizationId'] ?? 'Organização actual'}';
    final role = _roles[profile['role']] ?? '${profile['role'] ?? 'Operador'}';
    try {
      final changes = await showDialog<Json>(
        context: context,
        builder: (dialogContext) {
          final scheme = Theme.of(dialogContext).colorScheme;
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primary,
                          child: Icon(
                            FluentSystemIcons.account,
                            color: scheme.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perfil de acesso',
                                style: Theme.of(dialogContext)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Gerencie os seus dados de acesso ao $_institutionName',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(FluentSystemIcons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _profileInfoChip(
                          dialogContext,
                          FluentSystemIcons.shield,
                          'Perfil',
                          role,
                        ),
                        _profileInfoChip(
                          dialogContext,
                          FluentSystemIcons.business,
                          'Organização',
                          organization,
                        ),
                        _profileInfoChip(
                          dialogContext,
                          FluentSystemIcons.check,
                          'Estado',
                          profile['active'] == false ? 'Inactivo' : 'Activo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Informações pessoais',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(FluentSystemIcons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email profissional',
                        prefixIcon: Icon(FluentSystemIcons.mail),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: Icon(FluentSystemIcons.phone),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(
                          FluentSystemIcons.lock,
                          size: 17,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'O perfil e a organização são geridos pelo administrador.',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(dialogContext, {
                            'name': name.text.trim(),
                            'email': email.text.trim(),
                            'phone': phone.text.trim(),
                          }),
                          icon: const Icon(FluentSystemIcons.check),
                          label: const Text('Guardar alterações'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (changes == null || !mounted) return;
      if (profile['guest'] == true) {
        profile.addAll(changes);
        await _feedback(
          'Perfil actualizado nesta sessão.',
          title: 'Perfil actualizado',
          success: true,
        );
        return;
      }
      await api.write('PATCH', '/me', changes);
      await widget.session.verify();
      if (mounted) {
        await _feedback(
          'Perfil actualizado com sucesso.',
          title: 'Perfil actualizado',
          success: true,
        );
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        await _feedback(
          error.message,
          title: 'Perfil não actualizado',
          success: false,
        );
      }
    } catch (_) {
      if (mounted) {
        await _feedback(
          'Não foi possível actualizar o perfil.',
          title: 'Perfil não actualizado',
          success: false,
        );
      }
    } finally {
      name.dispose();
      email.dispose();
      phone.dispose();
    }
  }

  Widget _profileInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
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

  static const _mockNotifications = [
    (
      icon: FluentSystemIcons.warning,
      title: 'Pagamento em atraso',
      message: 'Existem prestações que precisam de acompanhamento.',
      time: 'Há 12 min',
    ),
    (
      icon: FluentSystemIcons.document,
      title: 'Documentação pendente',
      message: 'Um cliente aguarda revisão de identificação.',
      time: 'Há 1 h',
    ),
    (
      icon: FluentSystemIcons.check,
      title: 'Operação confirmada',
      message: 'O último desembolso foi processado com sucesso.',
      time: 'Ontem',
    ),
  ];

  Widget _notificationMenu() {
    final scheme = Theme.of(context).colorScheme;
    final badge = metrics['overdue_cents'] == null ? 0 : 6;
    return PopupMenuButton<String>(
      tooltip: 'Centro de notificações',
      offset: const Offset(0, 12),
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 390),
      color: scheme.surfaceContainerHigh,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(FluentSystemIcons.notifications),
          if (badge > 0)
            Positioned(
              right: -7,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      onSelected: (value) async {
        if (value == 'pending') select('pending');
        if (value == 'read') {
          await _feedback(
            'Notificações marcadas como lidas.',
            title: 'Notificações actualizadas',
            success: true,
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Centro de notificações',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$badge novas',
                style: TextStyle(color: scheme.primary, fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final notification in _mockNotifications)
          PopupMenuItem<String>(
            enabled: false,
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(notification.icon, color: scheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.time,
                        style: TextStyle(color: scheme.primary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'pending',
          child: ListTile(
            dense: true,
            leading: Icon(FluentSystemIcons.pending),
            title: Text('Ver todas as pendências'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'read',
          child: ListTile(
            dense: true,
            leading: Icon(FluentSystemIcons.check),
            title: Text('Marcar como lidas'),
          ),
        ),
      ],
    );
  }

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
                              icon: const Icon(FluentSystemIcons.arrowBack),
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
                          icon: FluentSystemIcons.search,
                          onPressed: _openSearch,
                        ),
                        _navbarAction(
                          tooltip: 'Pendências',
                          icon: FluentSystemIcons.pending,
                          badge: pending.length,
                          onPressed: () => select('pending'),
                        ),
                        _notificationMenu(),
                        _navbarAction(
                          tooltip: 'Cobranças e tesouraria',
                          icon: FluentSystemIcons.payments,
                          badge: metrics['overdue_cents'] == null ? 0 : 0,
                          onPressed: () => select('payments'),
                        ),
                        PopupMenuButton<ThemeMode>(
                          tooltip: 'Tema',
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? FluentSystemIcons.brightness
                                : FluentSystemIcons.light,
                          ),
                          offset: const Offset(0, 12),
                          constraints: const BoxConstraints(minWidth: 250),
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (selected) =>
                              widget.onTheme?.call(selected),
                          itemBuilder: (_) {
                            final current = themeMode.value;
                            return [
                              PopupMenuItem<ThemeMode>(
                                enabled: false,
                                height: 76,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Aparência',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Escolha como o $_institutionName é apresentado',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final option in [
                                (
                                  ThemeMode.system,
                                  'Automático',
                                  FluentSystemIcons.brightness,
                                ),
                                (
                                  ThemeMode.light,
                                  'Claro',
                                  FluentSystemIcons.light,
                                ),
                                (
                                  ThemeMode.dark,
                                  'Escuro',
                                  FluentSystemIcons.brightness,
                                ),
                              ])
                                PopupMenuItem<ThemeMode>(
                                  value: option.$1,
                                  height: 58,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: current == option.$1
                                          ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: .10)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(option.$3, size: 19),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            option.$2,
                                            style: TextStyle(
                                              fontWeight: current == option.$1
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (current == option.$1)
                                          Icon(
                                            FluentSystemIcons.check,
                                            size: 18,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ];
                          },
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          tooltip: 'Conta',
                          icon: const Icon(FluentSystemIcons.account),
                          offset: const Offset(0, 12),
                          constraints: const BoxConstraints(minWidth: 285),
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) async {
                            if (value == 'logout')
                              await widget.session.logout();
                            if (value == 'organization')
                              await selectOrganization();
                            if (value == 'settings' && context.mounted)
                              select('settings');
                            if (value == 'profile' && context.mounted) {
                              await _showProfileDialog();
                            }
                          },
                          itemBuilder: (_) {
                            final profile = widget.session.profile ?? {};
                            final scheme = Theme.of(context).colorScheme;
                            final name = '${profile['name'] ?? 'Utilizador'}';
                            final role =
                                _roles[profile['role']] ??
                                '${profile['role'] ?? 'Operador'}';
                            final organization =
                                '${profile['organization_name'] ?? profile['organization'] ?? profile['organization_id'] ?? profile['organizationId'] ?? 'Organização actual'}';
                            final email =
                                '${profile['email'] ?? 'Acesso autenticado'}';
                            return [
                              PopupMenuItem<String>(
                                enabled: false,
                                height: 126,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary.withValues(
                                      alpha: .08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 23,
                                        backgroundColor: scheme.primary,
                                        child: Text(
                                          name
                                              .trim()
                                              .split(RegExp(r'\s+'))
                                              .take(2)
                                              .map((part) => part[0])
                                              .join()
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: scheme.onPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  FluentSystemIcons.check,
                                                  size: 14,
                                                  color: scheme.primary,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Sessão activa · $role',
                                                  style: TextStyle(
                                                    color: scheme.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
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
                              PopupMenuItem<String>(
                                enabled: false,
                                height: 48,
                                child: Row(
                                  children: [
                                    Icon(
                                      FluentSystemIcons.business,
                                      size: 18,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Organização',
                                            style: TextStyle(
                                              color: scheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                          Text(
                                            organization,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'profile',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(FluentSystemIcons.account),
                                  title: Text('Ver perfil'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'organization',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(FluentSystemIcons.business),
                                  title: Text('Mudar organização'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'settings',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(FluentSystemIcons.settings),
                                  title: Text('Definições da conta'),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    FluentSystemIcons.close,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  title: Text(
                                    'Terminar sessão',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ];
                          },
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
                            if (![
                              'dashboard',
                              'simulator',
                              'reports',
                              'pending',
                              'audit',
                              'settings',
                              'organization-settings',
                              'risk-scores',
                              'plans',
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
