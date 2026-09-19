import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

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
  audit,
  faq,
  settings,
  reconciliation,
  financialAnalysis,
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
    Area.audit => 'Auditoria',
    Area.faq => 'Guia rápido',
    Area.settings => 'Definições',
    Area.reconciliation => 'Conciliação bancária',
    Area.financialAnalysis => 'Análise financeira',
    Area.creditApproval => 'Aprovar crédito',
    Area.creditAuthorization => 'Autorizar crédito',
    Area.creditDisbursement => 'Desembolso',
    Area.creditStatus => 'Estado do crédito',
    Area.creditRestructuring => 'Reestruturação do crédito',
  };
  IconData get icon => switch (this) {
    Area.dashboard => Icons.home_outlined,
    Area.clients => Icons.people_outline,
    Area.applications ||
    Area.creditApproval ||
    Area.creditAuthorization => Icons.description_outlined,
    Area.portfolio ||
    Area.creditStatus ||
    Area.creditRestructuring => Icons.account_balance_wallet_outlined,
    Area.collections || Area.creditDisbursement => Icons.payments_outlined,
    Area.reports => Icons.analytics_outlined,
    Area.settings => Icons.settings_outlined,
    _ => Icons.apps_outlined,
  };
}

class SideBar extends StatelessWidget {
  const SideBar({
    required this.area,
    required this.onTap,
    required this.onSubmenu,
    super.key,
  });
  final Area area;
  final ValueChanged<Area> onTap;
  final ValueChanged<String> onSubmenu;
  @override
  Widget build(BuildContext context) => Container(
    width: 278,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          brandVisuals.value.heroGradientStart,
          brandVisuals.value.heroGradientEnd,
        ],
      ),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 28, 20, 30),
            child: Row(
              children: [
                BrandLogo(size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SysCredi',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      Text(
                        'Microcrédito, grandes histórias',
                        style: TextStyle(color: Color(0xFFB9C7D5), fontSize: 9),
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
                  Area.applications,
                  Area.portfolio,
                  Area.collections,
                ])
                  item(a),
                group('Etapas do crédito', Icons.account_balance_outlined, [
                  subItem(
                    'Análise financeira',
                    Icons.analytics_outlined,
                    Area.financialAnalysis,
                  ),
                  subItem(
                    'Aprovar crédito',
                    Icons.check_circle_outline,
                    Area.creditApproval,
                  ),
                  subItem(
                    'Autorizar crédito',
                    Icons.verified_outlined,
                    Area.creditAuthorization,
                  ),
                  subItem(
                    'Desembolso',
                    Icons.payments_outlined,
                    Area.creditDisbursement,
                  ),
                  subItem(
                    'Estado do crédito',
                    Icons.track_changes_outlined,
                    Area.creditStatus,
                  ),
                  subItem(
                    'Reestruturação do crédito',
                    Icons.account_balance_outlined,
                    Area.creditRestructuring,
                  ),
                ]),
                group('Clientes', Icons.people_outline, [
                  subItem('Indivíduos', Icons.person_outline, Area.clients),
                  subItem('Empresas', Icons.business_outlined, Area.clients),
                  subItem(
                    'Avalistas',
                    Icons.verified_user_outlined,
                    Area.clients,
                  ),
                  subItem('Co-assinantes', Icons.group_outlined, Area.clients),
                ]),
                item(Area.reports),
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
                for (final a in [Area.simulator, Area.products, Area.risk])
                  item(a),
                group('Financeiro', Icons.attach_money, [
                  subItem(
                    'Saldos e contas',
                    Icons.account_balance_wallet_outlined,
                    Area.accounts,
                  ),
                  subItem(
                    'Movimentos de caixa',
                    Icons.swap_horiz_outlined,
                    Area.treasury,
                  ),
                  subItem(
                    'Conciliação bancária',
                    Icons.fact_check_outlined,
                    Area.reconciliation,
                  ),
                  subItem('Estornos', Icons.undo_outlined, Area.portfolio),
                ]),
                group('Parametrização', Icons.tune_outlined, [
                  subItem(
                    'Produtos de crédito',
                    Icons.category_outlined,
                    Area.products,
                  ),
                  subItem(
                    'Definições institucionais',
                    Icons.settings_outlined,
                    Area.settings,
                  ),
                ]),
                group('Gestão de logs', Icons.lock_clock_outlined, [
                  subItem('Auditoria', Icons.history_outlined, Area.audit),
                ]),
                group('Administração', Icons.admin_panel_settings_outlined, [
                  subItem(
                    'Contabilidade',
                    Icons.menu_book_outlined,
                    Area.accounting,
                  ),
                  subItem('Sincronização', Icons.sync_outlined, Area.sync),
                  subItem('Alertas AML', Icons.shield_outlined, Area.aml),
                  subItem(
                    'Gerir utilizadores',
                    Icons.group_outlined,
                    Area.users,
                  ),
                  subItem(
                    'Cópias de segurança',
                    Icons.backup_outlined,
                    Area.backup,
                  ),
                ]),
                group('Instruções do sistema', Icons.video_library_outlined, [
                  subItem('Guia rápido', Icons.help_outline, Area.faq),
                ]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
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
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Como trabalhar no SysCredi'),
                          content: const SingleChildScrollView(
                            child: Text(
                              '1. Registe o cliente e verifique a identidade.\n\n2. Configure os produtos e simule as condições.\n\n3. Crie um pedido e avance pela análise e comité.\n\n4. Abra o pedido aprovado para registar o desembolso.\n\n5. Consulte o contrato e receba prestações em Cobranças.\n\n6. Acompanhe tesouraria, relatórios e auditoria. Consulte a auditoria e os relatórios no servidor.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text(
                        'Ver guia rápido',
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
          ? Colors.white.withValues(alpha: .16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: ListTile(
        dense: true,
        minLeadingWidth: 22,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        leading: Icon(
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
      leading: Icon(icon, size: 24, color: Colors.white),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      children: children,
    ),
  );

  Widget subItem(String title, IconData icon, Area target) => ListTile(
    dense: true,
    leading: Icon(icon, size: 20, color: const Color(0xFFB9C7D5)),
    title: Text(
      title,
      style: const TextStyle(color: Color(0xFFB9C7D5), fontSize: 13),
    ),
    onTap: () {
      if (title == 'Indivíduos' ||
          title == 'Empresas' ||
          title == 'Avalistas' ||
          title == 'Co-assinantes' ||
          title == 'Estornos' ||
          title == 'Receitas' ||
          title == 'Despesas' ||
          title == 'Desembolsos' ||
          title == 'Reembolsos') {
        onSubmenu(title);
      } else {
        onTap(target);
      }
    },
  );
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
          borderRadius: BorderRadius.circular(15),
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
              color: (danger ? Colors.redAccent : color ?? green).withValues(
                alpha: .10,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              size: 25,
              color: danger
                  ? Colors.redAccent
                  : color ?? const Color(0xFF3C6574),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  top: Radius.circular(20),
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
          borderRadius: BorderRadius.circular(11),
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
