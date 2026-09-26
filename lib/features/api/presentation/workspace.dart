import 'dart:async';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syscredi/core/widgets/equal_button_group.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/fluent_design.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/csv/csv_codec.dart';
import '../../../core/localization/user_messages.dart';
import '../domain/money.dart';
import '../domain/formatters.dart';
import '../domain/repository.dart';
import '../application/subscription_service.dart';
import 'form.dart';
import 'navigation.dart';
import 'search_dialog.dart';
import 'session_view_model.dart';
import 'simulator_panel.dart';
import 'credit_stages.dart';
import 'portfolio_views.dart';
import 'report_views.dart';
import 'credit_products.dart';
import 'client_contract_documents.dart';
import 'finance_views.dart';
import 'plans_view.dart';
import 'audit_logs_view.dart';
import 'admin_views.dart';
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
  'report-exports': 'Exportações',
  'report-records': 'Registos',
  'report-letters': 'Cartas',
  'report-bm': 'Carta para BM',
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
  'bim': 'Millennium BIM',
  'bci': 'BCI',
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
  static const _pendingRefreshInterval = Duration(seconds: 3);
  static const _isWidgetTest = bool.fromEnvironment('FLUTTER_TEST');
  static const _genderOptions = {
    'male': 'Masculino',
    'female': 'Feminino',
    'other': 'Outro',
    'not_informed': 'Prefere não informar',
  };

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
    if (widget.session.analyst || widget.session.manager)
      const _Section(
        'financial-analysis',
        'Análise financeira',
        Icons.analytics_outlined,
      ),
    if (widget.session.analyst || widget.session.manager)
      const _Section('credit-approval', 'Aprovar crédito', Icons.check),
    if (widget.session.manager)
      const _Section(
        'credit-authorization',
        'Autorizar crédito',
        Icons.assignment_turned_in_outlined,
      ),
    if (widget.session.manager)
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
      const _Section('branches', 'Agências', Icons.business_outlined),
      const _Section('roles', 'Perfis', Icons.shield),
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
  List<Json> notifications = [];
  List<PendingWrite> pending = [];
  String? organizationName;
  bool loading = true, refreshing = false, busy = false, foreground = true;
  SubscriptionStatus? subscription;
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
      repository: api,
    );
    institutionSettings.load().then((_) {
      if (mounted && institutionSettings.error == null)
        applyInstitutionSettings(institutionSettings.saved);
    });
    _resolveOrganizationName();
    _loadSubscription();
    load();
    if (!_isWidgetTest) _schedulePendingRefresh();
  }

  Future<void> _loadSubscription() async {
    final value = await SubscriptionService(
      api,
    ).status(organizationId: _organizationId);
    if (!mounted) return;
    setState(() {
      subscription = value;
      if (!value.active) route = 'dashboard';
    });
  }

  String _subscriptionSubtitle() {
    final value = subscription;
    if (value == null) return 'A carregar plano...';
    if (!value.active) return 'Trial expirado';
    if (value.trial) {
      final days = value.trialDaysLeft;
      return 'Plano atual: Trial · $days ${days == 1 ? 'dia' : 'dias'}';
    }
    final plan = switch (value.plan?.toLowerCase()) {
      'quarterly' => 'Trimestral',
      'semiannual' => 'Semestral',
      'annual' => 'Anual',
      'lifetime' => 'Vitalício',
      final label? when label.isNotEmpty => value.plan!,
      _ => 'Activo',
    };
    return 'Plano atual: $plan';
  }

  String? _subscriptionPackage() {
    final value = subscription;
    if (value == null || !value.active || value.trial) return null;
    return value.package ?? 'basic';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) {
      _refreshPending();
      _refreshNotifications();
      if (!loading && !busy) load();
      if (!_isWidgetTest) _schedulePendingRefresh();
    } else {
      timer?.cancel();
    }
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

  void _schedulePendingRefresh() {
    timer?.cancel();
    if (!mounted || !foreground || route == 'plans') return;
    timer = Timer(_pendingRefreshInterval, () async {
      await Future.wait([_refreshPending(), _refreshNotifications()]);
      if (mounted && foreground) _schedulePendingRefresh();
    });
  }

  Future<void> _refreshPending() async {
    if (!mounted || !foreground || route == 'plans') return;
    try {
      final value = await api.pending();
      if (!mounted) return;
      final changed =
          value.length != pending.length ||
          value.asMap().entries.any(
            (entry) =>
                entry.key >= pending.length ||
                entry.value.key != pending[entry.key].key,
          );
      if (changed) setState(() => pending = value);
    } catch (_) {
      // Badge refresh is best-effort and must never interrupt the active view.
    }
  }

  Future<void> _refreshNotifications() async {
    if (!mounted || !foreground || route == 'plans') return;
    try {
      final value = await api.get('/notifications?limit=100&offset=0') as List;
      final loaded = value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (!mounted) return;
      final changed =
          loaded.length != notifications.length ||
          loaded.asMap().entries.any(
            (entry) =>
                entry.key >= notifications.length ||
                entry.value['id'] != notifications[entry.key]['id'] ||
                entry.value['read_at'] != notifications[entry.key]['read_at'],
          );
      if (changed) setState(() => notifications = loaded);
    } catch (_) {
      // Notification badge refresh is best-effort, like pending operations.
    }
  }

  String get _profileOrganizationName {
    final profile = widget.session.profile ?? const <String, dynamic>{};
    for (final key in ['organization_name', 'organizationName']) {
      final value = '${profile[key] ?? ''}'.trim();
      if (value.isNotEmpty) return value;
    }
    final resolved = organizationName?.trim() ?? '';
    return resolved.isEmpty ? 'Organização actual' : resolved;
  }

  String get _organizationId {
    final profile = widget.session.profile ?? const <String, dynamic>{};
    return '${profile['organization_id'] ?? profile['organizationId'] ?? ''}'
        .trim();
  }

  Future<void> _resolveOrganizationName() async {
    final profile = widget.session.profile ?? const <String, dynamic>{};
    final embedded =
        '${profile['organization_name'] ?? profile['organizationName'] ?? ''}'
            .trim();
    if (embedded.isNotEmpty) {
      if (mounted) setState(() => organizationName = embedded);
      return;
    }
    final currentId =
        '${profile['organization_id'] ?? profile['organizationId'] ?? ''}'
            .trim();
    if (currentId.isEmpty || profile['guest'] == true) return;
    try {
      final raw = await api.get('/organizations/mine') as List;
      final current = raw.whereType<Map>().cast<Map>().firstWhere(
        (row) => '${row['id']}' == currentId,
        orElse: () => const {},
      );
      final name = '${current['name'] ?? ''}'.trim();
      if (mounted && name.isNotEmpty) setState(() => organizationName = name);
    } catch (_) {
      // The profile menu falls back to a neutral label, never to an ID.
    }
  }

  Future<void> load() async {
    final current = ++generation, target = route;
    if (target == 'plans') {
      if (mounted && (loading || refreshing)) {
        setState(() {
          loading = false;
          refreshing = false;
          error = null;
        });
      }
      return;
    }
    final initialLoad = rows.isEmpty && metrics.isEmpty && pending.isEmpty;
    setState(() {
      loading = initialLoad;
      refreshing = !initialLoad;
      error = null;
    });
    if (_creditStageRoutes.contains(target) ||
        _financeAreas.containsKey(target) ||
        target == 'audit' ||
        target == 'products' ||
        target.startsWith('report-') ||
        target.startsWith('admin-') ||
        [
          'credit-portfolio',
          'loans',
          'contracts',
          'portfolio',
          'collections',
        ].contains(target) ||
        target == 'settings' ||
        target == 'general-settings' ||
        target == 'organization-settings') {
      await _refreshPending();
      if (mounted && current == generation) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
      return;
    }
    try {
      await widget.session.verify();
      if (!mounted || current != generation) return;
      final notificationsFuture = api
          .get('/notifications?limit=3&offset=0')
          .catchError((_) => <Json>[]);
      final pendingFuture = api.pending().catchError(
        (_) => List<PendingWrite>.from(pending),
      );
      final value = target == 'pending'
          ? await pendingFuture
          : await api.get(
              target == 'dashboard' || target == 'simulator'
                  ? '/dashboard'
                  : target == 'reports'
                  ? '/reports/portfolio'
                  : target == 'settings'
                  ? '/organization-settings?limit=50&offset=$offset&q=${Uri.encodeQueryComponent(search.text.trim())}'
                  : '/$target?limit=50&offset=$offset&q=${Uri.encodeQueryComponent(search.text.trim())}',
            );
      final notificationValue = await notificationsFuture;
      final pendingValue = await pendingFuture;
      if (!mounted || current != generation) return;
      setState(() {
        notifications = (notificationValue as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        pending = pendingValue;
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
      if (mounted && current == generation) {
        setState(() {
          loading = false;
          refreshing = false;
        });
      }
    }
  }

  Future<void> select(String next) async {
    if (busy) return;
    if (subscription?.active == false && next != 'plans') next = 'dashboard';
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
      updated = null;
      search.clear();
    });
    if (next == 'plans') {
      timer?.cancel();
      if (mounted) {
        setState(() {
          loading = false;
          refreshing = false;
          error = null;
        });
      }
      return;
    } else if (!_isWidgetTest) {
      _schedulePendingRefresh();
    }
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
    } catch (failure) {
      if (mounted) {
        await _feedback(
          userMessage(failure),
          title: 'Operação não confirmada',
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await _refreshPending();
        await load();
      }
    }
  }

  Future<void> _closeAccountingPeriod() async {
    var selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Encerrar período contabilístico'),
          content: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Período contabilístico'),
            subtitle: Text(
              '${selectedMonth.month.toString().padLeft(2, '0')}/${selectedMonth.year}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: selectedMonth,
                firstDate: DateTime(2000),
                lastDate: DateTime(DateTime.now().year + 10, 12, 31),
                helpText: 'Seleccione o período contabilístico',
                cancelText: 'Cancelar',
                confirmText: 'Seleccionar',
              );
              if (picked != null) {
                setDialogState(
                  () => selectedMonth = DateTime(picked.year, picked.month),
                );
              }
            },
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
      ),
    );
    if (confirmed != true) return;
    final month =
        '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
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
        Field('gender', 'Género', options: _genderOptions),
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
        Field('gender', 'Género', options: _genderOptions),
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
      'branches' => const [
        Field('code', 'Código'),
        Field('name', 'Nome'),
        Field('address', 'Endereço', optional: true),
        Field('location', 'Localização', optional: true),
      ],
      'roles' => const [
        Field('code', 'Código'),
        Field('name', 'Nome'),
        Field(
          'permissions',
          'Permissões separadas por vírgula',
          optional: true,
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
      final payload = route == 'roles'
          ? {
              ...data,
              'permissions': '${data['permissions'] ?? ''}'
                  .split(',')
                  .map((value) => value.trim().toUpperCase())
                  .where((value) => value.isNotEmpty)
                  .toSet()
                  .toList(),
            }
          : data;
      await mutate(
        route == 'users' ? 'POST' : 'POST',
        route == 'users' ? '/organizations/members/invite' : '/$route',
        payload,
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
      final clients = <Json>[];
      for (final values in records.skip(1)) {
        final row = {
          for (var i = 0; i < header.length && i < values.length; i++)
            header[i]: values[i].trim(),
        };
        clients.add({
          'name': row['nome'] ?? '',
          'phone': row['telemovel'] ?? '',
          'document': row['documento'] ?? '',
          'activity': row['actividade'] ?? '',
          'location': row['localizacao'] ?? '',
          'clientType': 'individual',
        });
      }
      final result = Map<String, dynamic>.from(
        await api.write('POST', '/clients/import', {'clients': clients}) as Map,
      );
      if (mounted) {
        await _feedback(
          'Total: ${result['total'] ?? clients.length}\n'
          'Importados: ${result['imported'] ?? 0}\n'
          'Duplicados: ${result['duplicates'] ?? 0}\n'
          'Inválidos/falhas: ${result['invalid'] ?? 0}',
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
      'document',
      'Número do documento',
      initial: row?['document']?.toString() ?? '',
    ),
    Field(
      'activity',
      'Actividade profissional',
      initial: row?['activity']?.toString() ?? '',
    ),
    Field(
      'location',
      'Localização',
      initial:
          row?['location']?.toString() ?? row?['address']?.toString() ?? '',
    ),
    Field(
      'birthDate',
      'Data de nascimento',
      kind: 'date',
      optional: true,
      initial: row?['birth_date']?.toString() ?? '',
    ),
    Field(
      'maritalStatus',
      'Estado civil',
      optional: true,
      initial: row?['marital_status']?.toString() ?? '',
    ),
    Field(
      'gender',
      'Género',
      options: _genderOptions,
      initial: row?['gender']?.toString() ?? '',
    ),
    Field(
      'address',
      'Endereço',
      optional: true,
      initial: row?['address']?.toString() ?? '',
    ),
    Field(
      'monthlyIncomeCents',
      'Rendimento mensal (MT)',
      kind: 'money',
      optional: true,
      initial: row?['monthly_income_cents'] == null
          ? ''
          : '${(int.tryParse('${row?['monthly_income_cents']}') ?? 0) / 100}',
    ),
    Field(
      'monthlyExpensesCents',
      'Despesas mensais (MT)',
      kind: 'money',
      optional: true,
      initial: row?['monthly_expenses_cents'] == null
          ? ''
          : '${(int.tryParse('${row?['monthly_expenses_cents']}') ?? 0) / 100}',
    ),
    Field(
      'dependents',
      'Dependentes',
      kind: 'nonNegativeInt',
      optional: true,
      initial: row?['dependents']?.toString() ?? '',
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
      Field(
        'gender',
        'Género',
        options: _genderOptions,
        initial: '${row['gender'] ?? ''}',
      ),
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
      Field('expiresAt', 'Validade do documento', kind: 'date'),
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
    if (const {'phone', 'telephone', 'contact', 'mobile'}.contains(key)) {
      return formatPhone(value);
    }
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
            'branches',
            'roles',
          ].contains(route));

  Widget _dashboardBody() {
    int metric(String key) => int.tryParse('${metrics[key] ?? 0}') ?? 0;
    final activeClients = '${metric('clients')}';
    final activeLoans = metric('active_loans');
    final pendingRequests = '${metric('pending_requests')}';
    final outstanding = money(metrics['outstanding_cents']);
    final overdue = metric('overdue_cents');
    final disbursed = metric('disbursed_this_month_cents');
    final collected = metric('collected_this_month_cents');
    final trends = _dashboardTrends();
    final disbursedTrend = [
      for (final row in trends) intValue(row['disbursed_cents']),
    ];
    final collectedTrend = [
      for (final row in trends) intValue(row['collected_cents']),
    ];
    final requestTrend = [for (final row in trends) intValue(row['requests'])];
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
                  money(disbursed),
                  '$activeLoans créditos activos',
                  Icons.credit_card_outlined,
                  scheme.primary,
                ),
                _remoteKpi(
                  'Capital em atraso',
                  money(overdue),
                  'prestações vencidas',
                  Icons.warning_amber_rounded,
                  scheme.error,
                ),
                _remoteKpi(
                  'Juros em atraso',
                  money(0),
                  'não separado pela API',
                  Icons.error_outline_rounded,
                  scheme.error,
                ),
                _remoteKpi(
                  'Clientes activos',
                  activeClients,
                  'clientes cadastrados',
                  Icons.people_alt_outlined,
                  scheme.secondary,
                ),
                _remoteKpi(
                  'Desembolso diário',
                  money(disbursed),
                  'total do mês actual',
                  Icons.payments_outlined,
                  scheme.tertiary,
                ),
                _remoteKpi(
                  'Reembolso diário',
                  money(collected),
                  'total do mês actual',
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
              'Desembolsos e cobranças',
              'Desembolsado',
              'Cobrado',
              scheme.error,
              scheme.secondary,
              _interleaveDashboardSeries(disbursedTrend, collectedTrend),
            ),
            const SizedBox(height: 20),
            _chartPanel(
              'Pedidos de crédito',
              'Pedidos criados',
              'Referência',
              scheme.secondary,
              scheme.error,
              _interleaveDashboardSeries(
                requestTrend,
                List<num>.filled(requestTrend.length, 0),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Json> _dashboardTrends() {
    final raw = metrics['trends'];
    if (raw is! Map) return const [];
    final rows = raw['12'] ?? raw['6'] ?? raw['3'];
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<num> _interleaveDashboardSeries(List<num> first, List<num> second) {
    final values = <num>[];
    final length = math.max(first.length, second.length);
    for (var index = 0; index < length; index++) {
      values.add(index < first.length ? first[index] : 0);
      values.add(index < second.length ? second[index] : 0);
    }
    return values;
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
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 16),
          const SizedBox(width: 8),
          Text(
            _dashboardPeriodLabel(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _dashboardPeriodLabel() {
    final date = DateTime.tryParse('${metrics['as_of'] ?? ''}')?.toLocal();
    if (date == null) return 'Dados actuais';
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
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
    if (subscription?.active == false && route != 'plans') {
      return _expiredTrialHome(subscription!);
    }
    final hasLoadedContent = switch (route) {
      'dashboard' || 'simulator' || 'reports' => metrics.isNotEmpty,
      'pending' => pending.isNotEmpty,
      _ => rows.isNotEmpty,
    };
    if (loading && !hasLoadedContent && !_creditStageRoutes.contains(route)) {
      return _loadingState(_loadingMessageForRoute(route));
    }
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
          RiskCenterView(rows: rows, repository: api, onRefresh: load),
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
    if (route == 'audit') return AuditLogsView(repository: api);
    if (route == 'credit-portfolio' ||
        route == 'loans' ||
        route == 'contracts' ||
        route == 'portfolio') {
      return PortfolioView(repository: api);
    }
    if (route == 'collections') return CollectionsView(repository: api);
    if (route == 'products') return CreditProductsView(repository: api);
    if (_financeAreas.containsKey(route)) {
      return FinanceView(area: _financeAreas[route]!, repository: api);
    }
    route = switch (route) {
      'finance-balances' => 'accounts',
      'finance-income' || 'finance-expenses' => 'cash-entries',
      'finance-disbursements' => 'loans',
      'finance-refunds' => 'payments',
      'finance-overdue' => 'loans',
      'finance-assets' => 'accounts',
      _ => route,
    };
    if (route.startsWith('report-')) {
      return ReportView(
        kind: _reportKinds[route] ?? 'Créditos',
        repository: api,
      );
    }
    if (route.startsWith('admin-')) {
      return AdminView(
        kind: route.substring('admin-'.length),
        repository: api,
        canManage: widget.session.manager,
      );
    }
    if (route == 'plans') {
      return PlansView(
        key: const ValueKey('syscredi-plans'),
        repository: api,
        organizationId: _organizationId,
        onActivated: () async {
          await _loadSubscription();
          if (mounted) select('dashboard');
        },
      );
    }
    if (_creditStageRoutes.contains(route)) {
      return CreditStagesView(
        stage: route,
        repository: api,
        role: '${widget.session.profile?['role'] ?? 'operator'}',
      );
    }
    if (route == 'settings' ||
        route == 'general-settings' ||
        route == 'organization-settings') {
      return InstitutionSettingsView(
        key: institutionSettingsKey,
        controller: institutionSettings,
        canAdminister: widget.session.manager,
        general: route == 'general-settings',
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
    if (route == 'simulator') return SimulatorPanel(repository: api);
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

  Widget _expiredTrialHome(SubscriptionStatus status) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: FluentSurface(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    color: scheme.onErrorContainer,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'O período de avaliação terminou',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'O plano padrão inclui 7 dias gratuitos. Para continuar a utilizar o Syscredi, escolha um plano e envie os identificadores do dispositivo e da organização ao proprietário.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: .46,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color.lerp(
                        scheme.outlineVariant,
                        scheme.primary,
                        .2,
                      )!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.verified_outlined,
                              color: scheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Identificadores para activação',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'A licença é associada à organização e controla os dispositivos autorizados.',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text:
                                      'Dispositivo: ${status.deviceId}\nOrganização: $_organizationId',
                                ),
                              );
                              if (!mounted) return;
                              await _feedback(
                                'Os identificadores foram copiados.',
                                title: 'IDs copiados',
                                success: true,
                              );
                            },
                            icon: const Icon(Icons.document, size: 17),
                            label: const Text('Copiar ambos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _ExpiredTrialIdentifier(
                        icon: Icons.card_membership_outlined,
                        label: 'ID do dispositivo',
                        value: status.deviceId,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: status.deviceId),
                          );
                          if (!mounted) return;
                          await _feedback(
                            'O ID do dispositivo foi copiado.',
                            title: 'ID copiado',
                            success: true,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _ExpiredTrialIdentifier(
                        icon: Icons.business_outlined,
                        label: 'ID da organização',
                        value: _organizationId,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: _organizationId),
                          );
                          if (!mounted) return;
                          await _feedback(
                            'O ID da organização foi copiado.',
                            title: 'ID copiado',
                            success: true,
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 17,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Envie estes IDs ao proprietário para gerar o código de activação. O limite de dispositivos depende do pacote Básico, Pro ou Premium.',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => select('plans'),
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Ver planos e activar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState(String message) =>
      CenteredLoadingState(message: message);

  String _loadingMessageForRoute(String value) => switch (value) {
    'clients' => 'A carregar clientes…',
    'businesses' => 'A carregar empresas…',
    'co-signers' => 'A carregar co-assinantes…',
    'client-guarantors' => 'A carregar avalistas…',
    'products' => 'A carregar produtos de crédito…',
    'dashboard' => 'A carregar o painel…',
    'payments' || 'collections' => 'A carregar pagamentos…',
    'receipts' => 'A carregar recibos…',
    'accounts' || 'finance-balances' => 'A carregar contas financeiras…',
    'cash-entries' => 'A carregar movimentos de tesouraria…',
    'journal' => 'A carregar lançamentos contabilísticos…',
    'accounting-periods' => 'A carregar períodos contabilísticos…',
    'reconciliations' => 'A carregar reconciliações…',
    'account-transfers' => 'A carregar transferências…',
    'aml-alerts' => 'A carregar alertas de compliance…',
    'field-visits' => 'A carregar visitas de campo…',
    'documents' => 'A carregar documentos…',
    'risk-scores' => 'A carregar avaliações de risco…',
    'audit' => 'A carregar eventos de auditoria…',
    'reports' => 'A carregar relatórios…',
    'pending' => 'A carregar operações pendentes…',
    'notifications' => 'A carregar notificações…',
    'branches' => 'A carregar agências…',
    'roles' => 'A carregar perfis e permissões…',
    'users' || 'admin-users' => 'A carregar utilizadores…',
    _ => 'A carregar dados…',
  };

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
        await _resolveOrganizationName();
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

  Widget _clientsBody() {
    if (route != 'clients') return _relatedClientsBody();
    final source = rows;
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
                  onPressed: busy ? null : importClients,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importar CSV'),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : create,
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
                            DataCell(Text(formatPhone(row['phone']))),
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
    final visible = rows;
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
                onPressed: busy ? null : create,
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
                row,
              ),
              _documentAction(
                dialogContext,
                'Contrato de confissão de dívida',
                'contrato_confissao.pdf',
                row,
              ),
              _documentAction(
                dialogContext,
                'Contrato de garantia',
                'contrato_de_garantia.pdf',
                row,
              ),
              _documentAction(
                dialogContext,
                'Estado do crédito',
                'credito_estado.pdf',
                row,
              ),
              _documentAction(
                dialogContext,
                'Recibo de desembolso',
                'recibo_de_desembolso.pdf',
                row,
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
    Json client,
  ) => ListTile(
    leading: const Icon(FluentSystemIcons.picture_as_pdf_outlined),
    title: Text(label),
    subtitle: Text(filename),
    trailing: const Icon(FluentSystemIcons.download),
    onTap: () {
      Navigator.pop(dialogContext);
      _downloadClientDocument(label, filename, client);
    },
  );

  Future<void> _downloadClientDocument(
    String title,
    String filename,
    Json client,
  ) async {
    try {
      final location = await getSaveLocation(suggestedName: filename);
      if (location == null) return;
      final branding = await InstitutionDocument.create();
      Json? loan;
      Json? guarantee;
      try {
        final loadedLoans = await api.get(
          '/loans?limit=100&offset=0&clientId=${Uri.encodeQueryComponent('${client['id']}')}',
        );
        final loans = loadedLoans is Map && loadedLoans['data'] is List
            ? loadedLoans['data'] as List
            : loadedLoans as List;
        if (loans.isNotEmpty)
          loan = Map<String, dynamic>.from(loans.first as Map);
      } catch (_) {
        // The document remains available with explicit placeholders.
      }
      if (filename == 'contrato_de_garantia.pdf') {
        try {
          final loaded = await api.get(
            '/client-guarantors?limit=100&offset=0&clientId=${Uri.encodeQueryComponent('${client['id']}')}',
          );
          final rows = loaded is Map && loaded['data'] is List
              ? loaded['data'] as List
              : loaded as List;
          if (rows.isNotEmpty) {
            guarantee = Map<String, dynamic>.from(rows.first as Map);
          }
        } catch (_) {
          // Missing guarantee data is represented by placeholders.
        }
      }
      final contracts = ClientContractDocuments(
        branding: branding,
        client: client,
      );
      final bytes = switch (filename) {
        'contrato.pdf' => await contracts.creditContract(loan: loan),
        'contrato_confissao.pdf' => await contracts.debtConfession(loan: loan),
        'contrato_de_garantia.pdf' => await contracts.guaranteeContract(
          loan: loan,
          guarantee: guarantee,
        ),
        _ => await _genericClientDocument(title, branding),
      };
      await XFile.fromData(
        bytes,
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

  Future<Uint8List> _genericClientDocument(
    String title,
    InstitutionDocument branding,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageTheme: branding.pageTheme(),
        header: branding.header,
        footer: branding.footer,
        build: (_) => [
          branding.title(
            title,
            subtitle: 'Documento emitido pelo sistema de gestão de crédito.',
          ),
          branding.information([
            'Emitido em: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            'Formato: A4',
          ]),
          pw.SizedBox(height: 18),
          pw.Text('${branding.data['documentNotes']}'),
          branding.signature('Comprovativo'),
        ],
      ),
    );
    return document.save();
  }

  Future<void> _removeClientRecord(
    Json row, {
    String resource = 'clients',
  }) async {
    final name = '${row['name'] ?? row['legal_name'] ?? 'este registo'}';
    final client = resource == 'clients';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(client ? 'Arquivar cliente?' : 'Remover registo?'),
        content: Text(
          client
              ? '“$name” deixará de aparecer entre os clientes activos. O histórico financeiro será preservado.'
              : 'Esta acção irá remover “$name”. Deseja continuar?',
        ),
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
            child: Text(client ? 'Arquivar' : 'Remover'),
          ),
        ],
      ),
    );
    if (confirmed == true && row['id'] != null && mounted) {
      if (client) {
        String? dateValue(Object? value) {
          if (value == null) return null;
          if (value is DateTime)
            return value.toIso8601String().split('T').first;
          final text = '$value';
          return text.contains('T') ? text.split('T').first : text;
        }

        int? integerValue(Object? value) => value == null
            ? null
            : value is int
            ? value
            : int.tryParse('$value');

        await mutate('PUT', '/clients/${row['id']}', {
          'clientType': '${row['client_type'] ?? 'individual'}',
          'name': '${row['name'] ?? ''}',
          'phone': '${row['phone'] ?? ''}',
          'document': '${row['document'] ?? ''}',
          'activity': '${row['activity'] ?? ''}',
          'location': '${row['location'] ?? ''}',
          if (dateValue(row['birth_date']) case final value?)
            'birthDate': value,
          if (row['gender'] != null) 'gender': row['gender'],
          if (row['marital_status'] != null)
            'maritalStatus': row['marital_status'],
          if (row['email'] != null) 'email': row['email'],
          if (row['address'] != null) 'address': row['address'],
          if (integerValue(row['monthly_income_cents']) case final value?)
            'monthlyIncomeCents': value,
          if (integerValue(row['monthly_expenses_cents']) case final value?)
            'monthlyExpensesCents': value,
          if (integerValue(row['dependents']) case final value?)
            'dependents': value,
          'archived': true,
          'version': integerValue(row['version']) ?? 1,
        });
      } else {
        await mutate('DELETE', '/$resource/${row['id']}', {});
      }
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
    _ when route.startsWith('report-') => Area.reports,
    'audit' => Area.audit,
    'plans' => Area.plans,
    'settings' => Area.settings,
    'organization-settings' => Area.settings,
    'general-settings' => Area.generalSettings,
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
    Area.settings => 'organization-settings',
    Area.generalSettings => 'general-settings',
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
    final organization = _profileOrganizationName;
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
    bool urgent = false,
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
                color: urgent
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                badge > 99 ? '99+' : '$badge',
                style: TextStyle(
                  color: urgent
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
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

  IconData _notificationIcon(String category) => switch (category) {
    'overdue' || 'compliance' => FluentSystemIcons.warning,
    'document' || 'approval' => FluentSystemIcons.document,
    _ => FluentSystemIcons.check,
  };

  bool _isUrgentPending(PendingWrite operation) {
    final path = operation.path.toLowerCase();
    return path.contains('/disburse') ||
        path.contains('/payments') ||
        path.contains('/cash-entries') ||
        path.contains('/account-transfers') ||
        path.contains('/loan-adjustments') ||
        path.contains('/authorization');
  }

  String _notificationTime(Object? value) {
    final created = DateTime.tryParse('$value')?.toLocal();
    if (created == null) return '';
    final elapsed = DateTime.now().difference(created);
    if (elapsed.inMinutes < 1) return 'Agora';
    if (elapsed.inHours < 1) return 'Há ${elapsed.inMinutes} min';
    if (elapsed.inDays < 1) return 'Há ${elapsed.inHours} h';
    if (elapsed.inDays == 1) return 'Ontem';
    return 'Há ${elapsed.inDays} dias';
  }

  Future<void> _markNotificationsRead() async {
    final unread = notifications
        .where((row) => row['read_at'] == null && row['archived_at'] == null)
        .toList();
    for (final row in unread) {
      await api.write('PATCH', '/notifications/${row['id']}/read', {});
    }
    if (!mounted) return;
    setState(() {
      for (final row in notifications) {
        row['read_at'] ??= DateTime.now().toUtc().toIso8601String();
      }
    });
  }

  Future<void> _markNotificationRead(Json notification) async {
    if (notification['read_at'] != null) return;
    await api.write('PATCH', '/notifications/${notification['id']}/read', {});
    if (!mounted) return;
    setState(() {
      notification['read_at'] = DateTime.now().toUtc().toIso8601String();
    });
  }

  Future<void> _archiveNotification(Json notification) async {
    await api.write(
      'PATCH',
      '/notifications/${notification['id']}/archive',
      {},
    );
    if (!mounted) return;
    setState(() {
      notification['archived_at'] = DateTime.now().toUtc().toIso8601String();
      notification['read_at'] ??= DateTime.now().toUtc().toIso8601String();
    });
  }

  Future<void> _restoreNotification(Json notification) async {
    await api.write(
      'PATCH',
      '/notifications/${notification['id']}/restore',
      {},
    );
    if (!mounted) return;
    setState(() => notification['archived_at'] = null);
  }

  Future<List<Json>> _loadNotificationCenter() async {
    try {
      final value = await api.get('/notifications?limit=100&offset=0') as List;
      final loaded = value
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      if (mounted) setState(() => notifications = loaded);
      return loaded;
    } catch (_) {
      if (notifications.isNotEmpty) {
        return notifications
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      rethrow;
    }
  }

  Future<void> _showNotificationCenter() async {
    await showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(100000, 64, 16, 0),
      color: Colors.transparent,
      elevation: 0,
      constraints: const BoxConstraints(minWidth: 390, maxWidth: 390),
      items: [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _NotificationCenterPopup(
            load: _loadNotificationCenter,
            markRead: _markNotificationRead,
            markAllRead: _markNotificationsRead,
            archive: _archiveNotification,
            restore: _restoreNotification,
            timeLabel: _notificationTime,
            iconFor: _notificationIcon,
            onPending: () {
              Navigator.pop(context);
              select('pending');
            },
          ),
        ),
      ],
    );
  }

  Widget _notificationMenu() {
    final scheme = Theme.of(context).colorScheme;
    final badge = notifications
        .where((row) => row['read_at'] == null && row['archived_at'] == null)
        .length;
    return IconButton(
      tooltip: 'Centro de notificações',
      onPressed: _showNotificationCenter,
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
                  badge > 99 ? '99+' : '$badge',
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
                activeRoute: route,
                subscriptionSubtitle: _subscriptionSubtitle(),
                subscriptionPackage: _subscriptionPackage(),
                onTap: (area) {
                  Navigator.of(context).pop();
                  _selectArea(area);
                },
                onSubmenu: (label) {
                  Navigator.of(context).pop();
                  _selectSubmodule(label);
                },
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
                  activeRoute: route,
                  subscriptionSubtitle: _subscriptionSubtitle(),
                  subscriptionPackage: _subscriptionPackage(),
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
                          urgent: pending.any(_isUrgentPending),
                          onPressed: () => select('pending'),
                        ),
                        _notificationMenu(),
                        _navbarAction(
                          tooltip: 'Cobrança',
                          icon: FluentSystemIcons.payments,
                          badge: metrics['overdue_cents'] == null ? 0 : 0,
                          onPressed: () => select('collections'),
                        ),
                        PopupMenuButton<ThemeMode>(
                          tooltip: 'Tema',
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                FluentTokens.radius8,
                              ),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Icon(
                              Theme.of(context).brightness == Brightness.dark
                                  ? FluentSystemIcons.brightness
                                  : FluentSystemIcons.light,
                              size: FluentTokens.iconMedium,
                            ),
                          ),
                          offset: const Offset(0, FluentTokens.space8),
                          constraints: const BoxConstraints(
                            minWidth: 310,
                            maxWidth: 330,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              FluentTokens.radius12,
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          onSelected: (selected) =>
                              widget.onTheme?.call(selected),
                          itemBuilder: (_) {
                            final current = themeMode.value;
                            final scheme = Theme.of(context).colorScheme;
                            return [
                              PopupMenuItem<ThemeMode>(
                                enabled: false,
                                height: 104,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    FluentTokens.space16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primary.withValues(alpha: .12),
                                        scheme.tertiary.withValues(alpha: .05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      FluentTokens.radius8,
                                    ),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: .18,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            FluentTokens.radius8,
                                          ),
                                        ),
                                        child: Icon(
                                          FluentSystemIcons.brightness,
                                          color: scheme.onPrimary,
                                          size: FluentTokens.iconMedium,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: FluentTokens.space12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Aparência',
                                              style: TextStyle(
                                                color: scheme.onSurface,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: FluentTokens.space4,
                                            ),
                                            Text(
                                              'Escolha o tema do $_institutionName',
                                              maxLines: 2,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              for (final option in [
                                (
                                  ThemeMode.system,
                                  'Automático',
                                  'Segue a definição do dispositivo',
                                  FluentSystemIcons.systemTheme,
                                ),
                                (
                                  ThemeMode.light,
                                  'Claro',
                                  'Superfícies claras e alto contraste',
                                  FluentSystemIcons.light,
                                ),
                                (
                                  ThemeMode.dark,
                                  'Escuro',
                                  'Confortável em ambientes com pouca luz',
                                  FluentSystemIcons.darkTheme,
                                ),
                              ])
                                PopupMenuItem<ThemeMode>(
                                  value: option.$1,
                                  height: 72,
                                  child: _ThemeMenuOption(
                                    icon: option.$4,
                                    title: option.$2,
                                    subtitle: option.$3,
                                    selected: current == option.$1,
                                  ),
                                ),
                            ];
                          },
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<String>(
                          tooltip: 'Conta',
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                FluentTokens.radius8,
                              ),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: const Icon(
                              FluentSystemIcons.account,
                              size: FluentTokens.iconMedium,
                            ),
                          ),
                          offset: const Offset(0, FluentTokens.space8),
                          constraints: const BoxConstraints(
                            minWidth: 320,
                            maxWidth: 340,
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              FluentTokens.radius12,
                            ),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          onSelected: (value) async {
                            if (value == 'logout')
                              await widget.session.logout();
                            if (value == 'organization')
                              await selectOrganization();
                            if (value == 'settings' && context.mounted) {
                              select('general-settings');
                            }
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
                            final organization = _profileOrganizationName;
                            final email =
                                '${profile['email'] ?? 'Acesso autenticado'}';
                            return [
                              PopupMenuItem<String>(
                                enabled: false,
                                height: 132,
                                child: Container(
                                  padding: const EdgeInsets.all(
                                    FluentTokens.space16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        scheme.primary.withValues(alpha: .12),
                                        scheme.secondary.withValues(alpha: .06),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      FluentTokens.radius8,
                                    ),
                                    border: Border.all(
                                      color: scheme.primary.withValues(
                                        alpha: .18,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            FluentTokens.radius12,
                                          ),
                                          boxShadow: FluentTokens.elevation(
                                            context,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          name.trim().isEmpty
                                              ? 'U'
                                              : name
                                                    .trim()
                                                    .split(RegExp(r'\s+'))
                                                    .where(
                                                      (part) => part.isNotEmpty,
                                                    )
                                                    .take(2)
                                                    .map((part) => part[0])
                                                    .join()
                                                    .toUpperCase(),
                                          style: TextStyle(
                                            color: scheme.onPrimary,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: FluentTokens.space12,
                                      ),
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
                                            const SizedBox(
                                              height: FluentTokens.space2,
                                            ),
                                            Text(
                                              email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: scheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: FluentTokens.space8,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        FluentTokens.space8,
                                                    vertical:
                                                        FluentTokens.space4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: scheme.primary
                                                    .withValues(alpha: .10),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      FluentTokens.radius6,
                                                    ),
                                              ),
                                              child: Text(
                                                role,
                                                style: TextStyle(
                                                  color: scheme.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
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
                                height: 58,
                                child: _ProfileMenuOrganization(
                                  organization: organization,
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'profile',
                                child: _ProfileMenuAction(
                                  icon: FluentSystemIcons.account,
                                  title: 'Ver perfil',
                                  subtitle: 'Dados pessoais e segurança',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'organization',
                                child: _ProfileMenuAction(
                                  icon: FluentSystemIcons.business,
                                  title: 'Mudar organização',
                                  subtitle: 'Trocar o espaço de trabalho',
                                ),
                              ),
                              PopupMenuItem(
                                value: 'settings',
                                child: _ProfileMenuAction(
                                  icon: FluentSystemIcons.settings,
                                  title: 'Definições gerais',
                                  subtitle:
                                      'Segurança, aparência e preferências',
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'logout',
                                child: _ProfileMenuAction(
                                  icon: FluentSystemIcons.close,
                                  title: 'Terminar sessão',
                                  subtitle: 'Sair deste dispositivo',
                                  destructive: true,
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),
                    if ((refreshing || busy) && route != 'plans')
                      const LinearProgressIndicator(),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const BrandWatermarkOverlay(),
                          SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!route.startsWith('admin-') &&
                                    !route.startsWith('report-') &&
                                    !_financeAreas.containsKey(route) &&
                                    ![
                                      'dashboard',
                                      'simulator',
                                      'reports',
                                      'pending',
                                      'audit',
                                      'settings',
                                      'general-settings',
                                      'organization-settings',
                                      'risk-scores',
                                      'plans',
                                      'collections',
                                      'products',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpiredTrialIdentifier extends StatelessWidget {
  const _ExpiredTrialIdentifier({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .8)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value.isEmpty ? 'Não disponível' : value,
                  style: TextStyle(
                    color: value.isEmpty ? scheme.error : scheme.primary,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar $label',
            onPressed: value.isEmpty ? null : onCopy,
            icon: const Icon(Icons.document),
          ),
        ],
      ),
    );
  }
}

class _NotificationCenterPopup extends StatefulWidget {
  const _NotificationCenterPopup({
    required this.load,
    required this.markRead,
    required this.markAllRead,
    required this.archive,
    required this.restore,
    required this.timeLabel,
    required this.iconFor,
    required this.onPending,
  });

  final Future<List<Json>> Function() load;
  final Future<void> Function(Json notification) markRead;
  final Future<void> Function() markAllRead;
  final Future<void> Function(Json notification) archive;
  final Future<void> Function(Json notification) restore;
  final String Function(Object? value) timeLabel;
  final IconData Function(String category) iconFor;
  final VoidCallback onPending;

  @override
  State<_NotificationCenterPopup> createState() =>
      _NotificationCenterPopupState();
}

class _NotificationCenterPopupState extends State<_NotificationCenterPopup> {
  late Future<List<Json>> future;
  String filter = 'all';
  bool working = false;
  bool refreshing = false;

  @override
  void initState() {
    super.initState();
    future = widget.load();
  }

  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      future = widget.load();
    });
    try {
      await future;
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 390,
      constraints: const BoxConstraints(maxHeight: 440),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FluentTokens.radius12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar',
                    visualDensity: VisualDensity.compact,
                    onPressed: working || refreshing ? null : refresh,
                    icon: refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(FluentSystemIcons.refresh, size: 17),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(FluentSystemIcons.close, size: 17),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<Json>>(
              future: future,
              builder: (context, snapshot) {
                final rows = snapshot.data ?? const <Json>[];
                final unread = rows
                    .where(
                      (row) =>
                          row['read_at'] == null && row['archived_at'] == null,
                    )
                    .length;
                final archived = rows
                    .where((row) => row['archived_at'] != null)
                    .length;
                return Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _notificationSelector(
                              value: 'all',
                              title: 'Todas',
                              subtitle: '${rows.length - archived}',
                              icon: FluentSystemIcons.notifications,
                            ),
                          ),
                          const SizedBox(width: FluentTokens.space8),
                          Expanded(
                            child: _notificationSelector(
                              value: 'unread',
                              title: 'Novas',
                              subtitle: '$unread',
                              icon: FluentSystemIcons.pending,
                            ),
                          ),
                          const SizedBox(width: FluentTokens.space8),
                          Expanded(
                            child: _notificationSelector(
                              value: 'archived',
                              title: 'Arquivo',
                              subtitle: '$archived',
                              icon: FluentSystemIcons.history,
                            ),
                          ),
                        ],
                      ),
                      if (unread > 0) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Marcar todas como lidas',
                            visualDensity: VisualDensity.compact,
                            onPressed: working
                                ? null
                                : () async {
                                    setState(() => working = true);
                                    try {
                                      await widget.markAllRead();
                                      await refresh();
                                    } finally {
                                      if (mounted) {
                                        setState(() => working = false);
                                      }
                                    }
                                  },
                            icon: const Icon(FluentSystemIcons.check, size: 17),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Expanded(
              child: FutureBuilder<List<Json>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _empty(
                      FluentSystemIcons.error,
                      'Não foi possível carregar',
                      action: IconButton(
                        tooltip: 'Tentar novamente',
                        onPressed: refresh,
                        icon: const Icon(FluentSystemIcons.refresh),
                      ),
                    );
                  }
                  final all = snapshot.data ?? const <Json>[];
                  final rows = switch (filter) {
                    'unread' =>
                      all
                          .where(
                            (row) =>
                                row['read_at'] == null &&
                                row['archived_at'] == null,
                          )
                          .toList(),
                    'archived' =>
                      all.where((row) => row['archived_at'] != null).toList(),
                    _ =>
                      all.where((row) => row['archived_at'] == null).toList(),
                  };
                  if (rows.isEmpty) {
                    return _empty(
                      FluentSystemIcons.notifications,
                      filter == 'unread'
                          ? 'Sem notificações novas'
                          : filter == 'archived'
                          ? 'Arquivo vazio'
                          : 'Sem notificações',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      indent: 52,
                      color: scheme.outlineVariant,
                    ),
                    itemBuilder: (context, index) => _tile(rows[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationSelector({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = filter == value;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: .07)
          : scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(FluentTokens.radius8),
      child: InkWell(
        borderRadius: BorderRadius.circular(FluentTokens.radius8),
        onTap: () => setState(() => filter = value),
        child: AnimatedContainer(
          duration: FluentTokens.fast,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FluentTokens.radius8),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
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
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? scheme.primary : scheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(FluentSystemIcons.check, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(Json notification) {
    final scheme = Theme.of(context).colorScheme;
    final unread = notification['read_at'] == null;
    final archived = notification['archived_at'] != null;
    final category = '${notification['category'] ?? ''}';
    return Material(
      color: unread
          ? scheme.primary.withValues(alpha: .055)
          : Colors.transparent,
      child: InkWell(
        onTap: working || !unread
            ? null
            : () async {
                setState(() => working = true);
                try {
                  await widget.markRead(notification);
                  setState(() {});
                } finally {
                  if (mounted) setState(() => working = false);
                }
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(FluentTokens.radius6),
                ),
                child: Icon(
                  widget.iconFor(category),
                  color: scheme.primary,
                  size: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${notification['title'] ?? 'Notificação'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${notification['body'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.timeLabel(notification['created_at']),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: archived
                    ? 'Restaurar notificação'
                    : 'Arquivar notificação',
                visualDensity: VisualDensity.compact,
                onPressed: working
                    ? null
                    : () async {
                        setState(() => working = true);
                        try {
                          if (archived) {
                            await widget.restore(notification);
                          } else {
                            await widget.archive(notification);
                          }
                          await refresh();
                        } finally {
                          if (mounted) setState(() => working = false);
                        }
                      },
                icon: Icon(
                  archived
                      ? FluentSystemIcons.restoreArchive
                      : FluentSystemIcons.archive,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(IconData icon, String text, {Widget? action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (action != null) action,
        ],
      ),
    ),
  );
}

class _ProfileMenuOrganization extends StatelessWidget {
  const _ProfileMenuOrganization({required this.organization});

  final String organization;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(FluentTokens.radius8),
          ),
          child: Icon(
            FluentSystemIcons.business,
            size: FluentTokens.iconSmall,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: FluentTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'ORGANIZAÇÃO',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: FluentTokens.space2),
              Text(
                organization,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuAction extends StatelessWidget {
  const _ProfileMenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FluentTokens.space4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: destructive
                  ? scheme.error.withValues(alpha: .10)
                  : scheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(FluentTokens.radius8),
            ),
            child: Icon(icon, size: FluentTokens.iconSmall, color: color),
          ),
          const SizedBox(width: FluentTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: FluentTokens.space2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: destructive
                        ? scheme.error.withValues(alpha: .78)
                        : scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            FluentSystemIcons.chevronRight,
            size: 14,
            color: destructive ? scheme.error : scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ThemeMenuOption extends StatelessWidget {
  const _ThemeMenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FluentTokens.space8,
        vertical: FluentTokens.space8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: .10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(FluentTokens.radius8),
        border: selected
            ? Border.all(color: scheme.primary.withValues(alpha: .24))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: .14)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(FluentTokens.radius8),
            ),
            child: Icon(
              icon,
              size: FluentTokens.iconSmall,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: FluentTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: FluentTokens.space2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FluentTokens.space8),
          AnimatedContainer(
            duration: FluentTokens.fast,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
              ),
            ),
            child: selected
                ? Icon(
                    FluentSystemIcons.check,
                    size: 12,
                    color: scheme.onPrimary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
