import 'package:flutter/material.dart' hide Icons;
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../settings/presentation/institution_branding.dart';
import 'faq_dialog.dart';

enum Area {
  dashboard,
  simulator,
  products,
  clients,
  applications,
  portfolio,
  collections,
  reports,
  risk,
  treasury,
  accounts,
  accounting,
  sync,
  aml,
  users,
  backup,
  plans,
  audit,
  faq,
  settings,
  reconciliation,
  financialAnalysis,
  creditFinancing,
  creditApproval,
  creditAuthorization,
  creditDisbursement,
  creditStatus,
  creditRestructuring,
}

extension AreaMeta on Area {
  String get label => switch (this) {
    Area.dashboard => 'Início',
    Area.simulator => 'Simulador',
    Area.products => 'Produtos de crédito',
    Area.clients => 'Clientes',
    Area.applications => 'Pedidos de crédito',
    Area.portfolio => 'Carteira de crédito',
    Area.collections => 'Cobranças',
    Area.reports => 'Relatórios',
    Area.risk => 'Central de risco',
    Area.treasury => 'Tesouraria',
    Area.accounts => 'Contas e saldos',
    Area.accounting => 'Contabilidade',
    Area.sync => 'Sincronização',
    Area.aml => 'Alertas AML',
    Area.users => 'Gerir utilizadores',
    Area.backup => 'Cópias de segurança',
    Area.plans => 'Planos e Subscrições',
    Area.audit => 'Auditoria',
    Area.faq => 'Guia rápido',
    Area.settings => 'Definições',
    Area.reconciliation => 'Conciliação bancária',
    Area.financialAnalysis => 'Análise financeira',
    Area.creditFinancing => 'Financiamento',
    Area.creditApproval => 'Aprovar crédito',
    Area.creditAuthorization => 'Autorizar crédito',
    Area.creditDisbursement => 'Desembolso',
    Area.creditStatus => 'Estado do crédito',
    Area.creditRestructuring => 'Reestruturação do crédito',
  };
  IconData get icon => switch (this) {
    Area.dashboard => FluentSystemIcons.home,
    Area.simulator => FluentSystemIcons.calculator,
    Area.products => FluentSystemIcons.productCatalog,
    Area.clients => FluentSystemIcons.people,
    Area.risk => FluentSystemIcons.shieldAlert,
    Area.applications => FluentSystemIcons.documentApproval,
    Area.creditFinancing => FluentSystemIcons.documentApproval,
    Area.creditApproval ||
    Area.creditAuthorization => FluentSystemIcons.document,
    Area.portfolio ||
    Area.creditStatus ||
    Area.creditRestructuring => FluentSystemIcons.wallet,
    Area.collections || Area.creditDisbursement => FluentSystemIcons.payments,
    Area.reports => FluentSystemIcons.analytics,
    Area.plans => FluentSystemIcons.subscriptions,
    Area.settings => FluentSystemIcons.settings,
    _ => FluentSystemIcons.apps,
  };
}

class SideBar extends StatelessWidget {
  const SideBar({
    required this.area,
    required this.activeRoute,
    required this.onTap,
    required this.onSubmenu,
    super.key,
  });
  final Area area;
  final String activeRoute;
  final ValueChanged<Area> onTap;
  final ValueChanged<String> onSubmenu;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([brandPalette, brandVisuals]),
    builder: (context, _) => _sidebar(context),
  );

  Widget _sidebar(BuildContext context) => Container(
    width: brandVisuals.value.compactSidebar
        ? 240
        : FluentTokens.navigationWidth,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            brandVisuals.value.heroGradientStart,
            brandPalette.value.primary,
            .32,
          )!,
          Color.lerp(
            brandVisuals.value.heroGradientEnd,
            brandPalette.value.secondary,
            .32,
          )!,
        ],
      ),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FluentTokens.space24,
              FluentTokens.space24,
              FluentTokens.space20,
              FluentTokens.space24,
            ),
            child: Row(
              children: [
                BrandLogo(size: 64),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InstitutionNameText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      InstitutionBioText(
                        style: TextStyle(color: Color(0xFFB9C7D5), fontSize: 9),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final a in [
                  Area.dashboard,
                  Area.portfolio,
                  Area.collections,
                ])
                  item(a),
                group('Etapas do crédito', FluentSystemIcons.flowChart, [
                  subItem(
                    'Financiamento',
                    FluentSystemIcons.documentApproval,
                    Area.creditFinancing,
                  ),
                  subItem(
                    'Análise financeira',
                    FluentSystemIcons.analytics,
                    Area.financialAnalysis,
                  ),
                  subItem(
                    'Aprovar crédito',
                    FluentSystemIcons.check,
                    Area.creditApproval,
                  ),
                  subItem(
                    'Autorizar crédito',
                    FluentSystemIcons.check,
                    Area.creditAuthorization,
                  ),
                  subItem(
                    'Desembolso',
                    FluentSystemIcons.payments,
                    Area.creditDisbursement,
                  ),
                  subItem(
                    'Estado do crédito',
                    FluentSystemIcons.analytics,
                    Area.creditStatus,
                  ),
                  subItem(
                    'Reestruturação do crédito',
                    FluentSystemIcons.wallet,
                    Area.creditRestructuring,
                  ),
                ]),
                group('Clientes', FluentSystemIcons.people, [
                  subItem('Indivíduos', FluentSystemIcons.person, Area.clients),
                  subItem('Empresas', FluentSystemIcons.business, Area.clients),
                  subItem('Avalistas', FluentSystemIcons.shield, Area.clients),
                  subItem(
                    'Co-assinantes',
                    FluentSystemIcons.people,
                    Area.clients,
                  ),
                ]),
                group('Relatórios', FluentSystemIcons.analytics, [
                  subItem(
                    'Em PDF',
                    FluentSystemIcons.picture_as_pdf_outlined,
                    Area.reports,
                  ),
                  subItem(
                    'Em Excel',
                    FluentSystemIcons.table_view_outlined,
                    Area.reports,
                  ),
                  subItem(
                    'Registos',
                    FluentSystemIcons.receipt_long_outlined,
                    Area.reports,
                  ),
                  subItem('Cartas', FluentSystemIcons.mail, Area.reports),
                  subItem(
                    'Mensal para BM',
                    FluentSystemIcons.calendar,
                    Area.reports,
                  ),
                  subItem(
                    'Trimestral para BM',
                    FluentSystemIcons.calendar,
                    Area.reports,
                  ),
                  subItem('Créditos', FluentSystemIcons.wallet, Area.reports),
                  subItem('Clientes', FluentSystemIcons.people, Area.reports),
                  subItem(
                    'Financeiros',
                    FluentSystemIcons.analytics,
                    Area.reports,
                  ),
                  subItem('Diversos', FluentSystemIcons.apps, Area.reports),
                ]),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 12, 10),
                  child: Text(
                    'GESTÃO E CONTROLO',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.4,
                      color: Color(0xFF8CA3B8),
                    ),
                  ),
                ),
                for (final a in [Area.simulator, Area.risk]) item(a),
                group('Financeiro', FluentSystemIcons.payments, [
                  subItem('Saldos', FluentSystemIcons.wallet, Area.accounts),
                  subItem('Estornos', FluentSystemIcons.refresh, Area.accounts),
                  subItem(
                    'Receitas',
                    FluentSystemIcons.analytics,
                    Area.accounts,
                  ),
                  subItem(
                    'Despesas',
                    FluentSystemIcons.analytics,
                    Area.accounts,
                  ),
                  subItem(
                    'Desembolsos',
                    FluentSystemIcons.payments,
                    Area.accounts,
                  ),
                  subItem(
                    'Reembolsos',
                    FluentSystemIcons.receipt_long_outlined,
                    Area.accounts,
                  ),
                  subItem(
                    'Prestações Vencidas',
                    FluentSystemIcons.warning,
                    Area.accounts,
                  ),
                  subItem('Ativos', FluentSystemIcons.wallet, Area.accounts),
                ]),
                group('Parametrização', FluentSystemIcons.settings, [
                  subItem(
                    'Produtos de crédito',
                    FluentSystemIcons.productCatalog,
                    Area.products,
                  ),
                  subItem(
                    'Definições institucionais',
                    FluentSystemIcons.settings,
                    Area.settings,
                  ),
                ]),
                group('Gestão de logs', FluentSystemIcons.lock, [
                  subItem('Auditoria', FluentSystemIcons.history, Area.audit),
                ]),
                group('Administração', FluentSystemIcons.admin, [
                  subItem(
                    'Contabilidade',
                    FluentSystemIcons.document,
                    Area.accounting,
                  ),
                  subItem('Sincronização', FluentSystemIcons.sync, Area.sync),
                  subItem('Alertas AML', FluentSystemIcons.shield, Area.aml),
                  subItem(
                    'Gerir utilizadores',
                    FluentSystemIcons.people,
                    Area.users,
                  ),
                  subItem(
                    'Cópias de segurança',
                    FluentSystemIcons.download,
                    Area.backup,
                  ),
                ]),
                item(Area.plans),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(FluentTokens.radius12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline, color: Colors.white, size: 25),
                  const SizedBox(height: 12),
                  const Text(
                    'Precisa de ajuda?',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Conheça cada etapa da sua operação de crédito.',
                    style: TextStyle(
                      color: Color(0xFFBDCAD6),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      onPressed: () => showHelpCenter(context),
                      child: const Text(
                        'Consultar FAQ',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget item(Area a) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Material(
      color: area == a
          ? brandPalette.value.primary.withValues(alpha: .30)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: ListTile(
        dense: true,
        minLeadingWidth: 22,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: !brandVisuals.value.navigationIcons
            ? null
            : Icon(
                a == Area.dashboard ? Icons.home_outlined : a.icon,
                size: 24,
                color: Colors.white,
              ),
        title: Text(
          a == Area.dashboard ? 'Início' : a.label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        onTap: () => onTap(a),
      ),
    ),
  );

  Widget group(String title, IconData icon, List<Widget> children) => Theme(
    data: ThemeData(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 15),
      childrenPadding: const EdgeInsets.only(left: 24),
      leading: !brandVisuals.value.navigationIcons
          ? null
          : Icon(icon, size: 24, color: Colors.white),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      children: children,
    ),
  );

  Widget subItem(String title, IconData icon, Area target) {
    final selected = _routeForSubmenu(title, target) == activeRoute;
    final foreground = selected ? Colors.white : const Color(0xFFB9C7D5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected
            ? brandPalette.value.primary.withValues(alpha: .30)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          leading: !brandVisuals.value.navigationIcons
              ? null
              : Icon(icon, size: 20, color: foreground),
          title: Text(
            title,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check, size: 17, color: Colors.white)
              : null,
          onTap: () {
            if (title == 'Indivíduos' ||
                title == 'Empresas' ||
                title == 'Avalistas' ||
                title == 'Co-assinantes' ||
                title == 'Estornos' ||
                title == 'Receitas' ||
                title == 'Despesas' ||
                title == 'Desembolsos' ||
                title == 'Reembolsos' ||
                title == 'Saldos' ||
                title == 'Prestações Vencidas' ||
                title == 'Ativos' ||
                title == 'Desembolsos' ||
                title == 'Receitas' ||
                title == 'Despesas' ||
                title == 'Em PDF' ||
                title == 'Em Excel' ||
                title == 'Registos' ||
                title == 'Cartas' ||
                title == 'Mensal para BM' ||
                title == 'Trimestral para BM' ||
                title == 'Créditos' ||
                title == 'Clientes' ||
                title == 'Financeiros' ||
                title == 'Diversos') {
              onSubmenu(title);
            } else {
              onTap(target);
            }
          },
        ),
      ),
    );
  }

  String _routeForSubmenu(String title, Area target) => switch (title) {
    'Indivíduos' => 'clients',
    'Empresas' => 'businesses',
    'Avalistas' => 'client-guarantors',
    'Co-assinantes' => 'co-signers',
    'Em PDF' || 'Créditos' => 'report-credit',
    'Em Excel' || 'Clientes' => 'report-client',
    'Registos' => 'report-registers',
    'Cartas' => 'report-letters',
    'Mensal para BM' => 'report-bom-monthly',
    'Trimestral para BM' => 'report-bom-quarterly',
    'Financeiros' => 'report-financial',
    'Diversos' => 'report-misc',
    'Saldos' => 'finance-balances',
    'Estornos' => 'finance-reversals',
    'Receitas' => 'finance-income',
    'Despesas' => 'finance-expenses',
    'Desembolsos' =>
      target == Area.creditDisbursement
          ? 'credit-disbursement'
          : 'finance-disbursements',
    'Reembolsos' => 'finance-refunds',
    'Prestações Vencidas' => 'finance-overdue',
    'Ativos' => 'finance-assets',
    'Produtos de crédito' => 'products',
    'Definições institucionais' => 'settings',
    'Auditoria' => 'audit',
    'Contabilidade' => 'admin-accounting',
    'Sincronização' => 'admin-sync',
    'Alertas AML' => 'admin-aml',
    'Gerir utilizadores' => 'admin-users',
    'Cópias de segurança' => 'admin-backup',
    _ => switch (target) {
      Area.creditFinancing => 'financing',
      Area.financialAnalysis => 'financial-analysis',
      Area.creditApproval => 'credit-approval',
      Area.creditAuthorization => 'credit-authorization',
      Area.creditDisbursement => 'credit-disbursement',
      Area.creditStatus => 'credit-status',
      Area.creditRestructuring => 'credit-restructuring',
      _ => '',
    },
  };
}

Future<void> showThemeModeMenu(
  BuildContext context,
  ValueChanged<ThemeMode>? onTheme,
) async {
  final mode = await showDialog<ThemeMode>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('Tema'),
      children: [
        for (final value in ThemeMode.values)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, value),
            child: Text(value.name),
          ),
      ],
    ),
  );
  if (mode != null) onTheme?.call(mode);
}

Future<void> showThemeModePicker(
  BuildContext context,
  ValueChanged<ThemeMode>? onTheme,
) => showThemeModeMenu(context, onTheme);

class AccountMenuHeader extends StatelessWidget {
  const AccountMenuHeader({
    this.name,
    this.email,
    this.role,
    this.onViewProfile,
    super.key,
  });
  final String? name, email, role;
  final VoidCallback? onViewProfile;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = brandPalette.value;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? [
                    palette.primary.withValues(alpha: .30),
                    palette.secondary.withValues(alpha: .34),
                  ]
                : [palette.primary.withValues(alpha: .12), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: palette.primary.withValues(alpha: dark ? .42 : .20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: brandPalette.value.primary,
                child: Text(
                  initials(displayUserName(name)),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 23,
                    letterSpacing: .5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayUserName(name),
                      style: TextStyle(
                        color: dark ? Colors.white : navy,
                        fontWeight: FontWeight.w600,
                        fontSize: 19,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayRole(role),
                      style: TextStyle(
                        color: dark
                            ? const Color(0xFFB5C7C5)
                            : const Color(0xFF617080),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 11,
                          color: Color(0xFF53BF8A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sessão activa',
                          style: TextStyle(
                            fontSize: 14,
                            color: brandPalette.value.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.person_outline, size: 19),
                label: const Text('Ver perfil'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  foregroundColor: dark
                      ? Colors.white
                      : const Color(0xFF263B55),
                  side: BorderSide(
                    color: dark
                        ? Colors.white.withValues(alpha: .62)
                        : const Color(0xFFC9D3DE),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String displayUserName(String? name) =>
    name == null || name.trim().isEmpty ? 'Utilizador' : name.trim();

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'SC';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String displayRole(String? role) {
  final value = role?.trim().toLowerCase() ?? '';
  return switch (value) {
    'manager' || 'gestor' || 'gestor de crédito' => 'Gestor de Crédito',
    'analyst' ||
    'analista' ||
    'avalista' ||
    'avalista de crédito' => 'Avalista de Crédito',
    'operator' || 'operador' || 'operador de crédito' => 'Operador de Crédito',
    _ when role != null && role.trim().isNotEmpty => role.trim(),
    _ => 'Operador de Crédito',
  };
}

class AccountMenuItem extends StatelessWidget {
  const AccountMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.danger = false,
    this.color,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool danger;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  (danger
                          ? Colors.redAccent
                          : color ?? brandPalette.value.primary)
                      .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 25,
              color: danger
                  ? Colors.redAccent
                  : color ?? brandPalette.value.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: danger
                        ? Colors.redAccent
                        : (dark ? Colors.white : navy),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFF9FB2B7)
                          : const Color(0xFF8795A3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 22,
            color: danger
                ? Colors.redAccent
                : (dark ? const Color(0xFF789196) : const Color(0xFFAFBBC4)),
          ),
        ],
      ),
    );
  }
}

class _AccountDialog extends StatelessWidget {
  const _AccountDialog({
    required this.name,
    required this.email,
    required this.role,
  });
  final String name, email, role;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = brandPalette.value;
    final surface = Theme.of(context).colorScheme.surface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Dialog(
      elevation: 18,
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [
                          palette.primary.withValues(alpha: .32),
                          palette.secondary.withValues(alpha: .36),
                        ]
                      : [palette.primary.withValues(alpha: .13), Colors.white],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: brandPalette.value.primary,
                    child: Text(
                      initials(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: dark ? Colors.white : navy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayRole(role),
                          style: TextStyle(
                            color: dark
                                ? const Color(0xFFB5C7C5)
                                : const Color(0xFF617080),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: Color(0xFF53BF8A),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sessão activa',
                              style: TextStyle(
                                color: brandPalette.value.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dados da conta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _profileDetail(
                    Icons.badge_outlined,
                    'Perfil de acesso',
                    displayRole(role),
                    muted,
                  ),
                  const SizedBox(height: 10),
                  _profileDetail(
                    Icons.alternate_email,
                    'Email',
                    email.isEmpty ? 'Não informado' : email,
                    muted,
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
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

  Widget _profileDetail(
    IconData icon,
    String label,
    String value,
    Color muted,
  ) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: brandPalette.value.primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: brandPalette.value.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ],
  );
}

Future<void> showNotificationCenter(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('Notificações'),
      content: Text('Não existem notificações novas.'),
    ),
  );
}
