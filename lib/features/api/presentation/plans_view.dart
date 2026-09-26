import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/fluent_design.dart';
import '../../../app/theme/fluent_icons_compat.dart';
import '../../../core/licensing/hardware_device_id.dart';
import '../../../core/widgets/activation_contact_card.dart';
import '../../../core/widgets/operation_feedback.dart';
import '../application/subscription_service.dart';
import '../domain/repository.dart';

class PlansView extends StatefulWidget {
  const PlansView({
    required this.repository,
    required this.organizationId,
    this.onActivated,
    super.key,
  });
  final Repository repository;
  final String organizationId;
  final VoidCallback? onActivated;

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  static const _licenseSecret = 'syscredi-license-v1-rotate-in-release';
  static const _organizationUserLimit = 4;
  String? _selected;
  String _current = 'Trial';
  String _currentPackage = 'Básico';
  int _trialDays = SubscriptionService.trialDaysTotal;
  final _activationCode = TextEditingController();
  String _deviceId = 'A CARREGAR...';
  bool _activating = false;
  bool _activationExpanded = true;

  static const _plans = <_Plan>[
    _Plan(
      'Trimestral',
      '1 459 MT',
      'a cada 3 meses',
      Icons.calendar_today_outlined,
      false,
    ),
    _Plan(
      'Semestral',
      '2 459 MT',
      'a cada 6 meses',
      Icons.calendar_today_outlined,
      false,
    ),
    _Plan(
      'Anual',
      '4 459 MT',
      'a cada 12 meses',
      Icons.verified_outlined,
      true,
    ),
    _Plan('Vitalício', '14 999 MT', 'pagamento único', Icons.wallet, false),
  ];

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final status = await SubscriptionService(widget.repository).status();
    if (!mounted) return;
    setState(() {
      _deviceId = status.deviceId;
      _current = status.trial ? 'Trial' : status.plan ?? 'Activo';
      _currentPackage = switch (status.package) {
        'pro' => 'Pro',
        'premium' => 'Premium',
        _ => 'Básico',
      };
      _trialDays = status.trialDaysLeft;
      _activationExpanded = status.trial;
    });
  }

  @override
  void dispose() {
    _activationCode.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = await HardwareDeviceId.resolve(prefs);
    if (mounted) setState(() => _deviceId = id.toUpperCase());
  }

  Future<void> _activate() async {
    final code = _activationCode.text.trim();
    if (code.isEmpty) {
      await showFeedbackDialog(
        context,
        title: 'Código necessário',
        message: 'Insira o código de ativação fornecido pelo proprietário.',
      );
      return;
    }
    setState(() => _activating = true);
    try {
      final parsed = _validateActivationCode(code);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('syscredi.license.plan', parsed.plan);
      await prefs.setString(
        'syscredi.license.expiresAt',
        parsed.expiresAt.toIso8601String(),
      );
      await prefs.setString('syscredi.license.code', code);
      await prefs.setString(
        'syscredi.license.organizationId',
        widget.organizationId,
      );
      await prefs.setString('syscredi.license.package', parsed.package);
      if (parsed.deviceLimit == null) {
        await prefs.remove('syscredi.license.deviceLimit');
      } else {
        await prefs.setInt('syscredi.license.deviceLimit', parsed.deviceLimit!);
      }
      await widget.repository.write('POST', '/subscription-history', {
        'plan': parsed.plan,
        'codeFingerprint': code,
        'expiresAt': parsed.expiresAt.toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _current = parsed.plan;
          _trialDays = 0;
        });
        widget.onActivated?.call();
      }
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Código activado',
          message: 'A activação foi confirmada pelo servidor.',
          success: true,
        );
      }
    } catch (failure) {
      if (mounted) {
        await showFeedbackDialog(
          context,
          title: 'Activação não concluída',
          message: '$failure',
          success: false,
        );
      }
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  _ActivationLicense _validateActivationCode(String code) {
    final normalizedCode = code.replaceAll(RegExp(r'\s+'), '');
    final parts = normalizedCode.split('|');
    if (parts.length != 7) {
      throw const FormatException(
        'Formato de licença inválido. Gere uma nova licença no Syscredi Activator atualizado.',
      );
    }
    final plan = parts[0];
    final expiresAt = DateTime.tryParse('${parts[1]}T23:59:59.999Z');
    final deviceId = parts[2].toLowerCase();
    final organizationId = parts[3].toLowerCase();
    final package = parts[4].toLowerCase();
    final deviceLimit = parts[5] == 'unlimited' ? null : int.tryParse(parts[5]);
    final signature = parts[6].toLowerCase();
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const FormatException('A licença está expirada.');
    }
    final expectedOrganization = widget.organizationId.trim().toLowerCase();
    if (expectedOrganization.isEmpty) {
      throw const FormatException(
        'O ID da organização não está disponível nesta sessão. Entre novamente antes de ativar.',
      );
    }
    if (organizationId != expectedOrganization) {
      throw FormatException(
        'A licença pertence a outra organização. Esperado: ${widget.organizationId}.',
      );
    }
    const validPlans = {'quarterly', 'semiannual', 'annual', 'lifetime'};
    if (!validPlans.contains(plan)) {
      throw const FormatException('O plano presente na licença é inválido.');
    }
    const validPackages = {'basic', 'pro', 'premium'};
    if (!validPackages.contains(package) ||
        (package != 'premium' && (deviceLimit == null || deviceLimit < 1))) {
      throw const FormatException('O pacote presente na licença é inválido.');
    }
    final prefix =
        '$plan|${parts[1]}|$deviceId|$organizationId|$package|${parts[5]}';
    final expected = Hmac(
      sha256,
      utf8.encode(_licenseSecret),
    ).convert(utf8.encode(prefix)).toString().substring(0, 32);
    if (signature != expected) {
      throw const FormatException(
        'A assinatura da licença é inválida. Copie novamente o código completo.',
      );
    }
    final label = switch (plan) {
      'quarterly' => 'Trimestral',
      'semiannual' => 'Semestral',
      'annual' => 'Anual',
      'lifetime' => 'Vitalício',
      _ => plan,
    };
    return _ActivationLicense(
      label,
      expiresAt,
      package: package,
      deviceLimit: deviceLimit,
    );
  }

  Future<void> _choose(_Plan plan) async {
    setState(() => _selected = plan.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ativar plano ${plan.name}'),
        content: Text(
          'Confirma a seleção do plano ${plan.name} por ${plan.price}?\n\nA ativação será associada a esta instalação do Syscredi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() => _selected = plan.name);
      await showFeedbackDialog(
        context,
        title: 'Código necessário',
        message: 'Insira o código de activação para confirmar ${plan.name}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final horizontal = compact
            ? 16.0
            : constraints.maxWidth < 900
            ? 22.0
            : 28.0;
        final gap = compact ? 12.0 : 16.0;
        final columns = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : 4;
        final cardWidth =
            (constraints.maxWidth - horizontal * 2 - gap * (columns - 1)) /
            columns;
        return SingleChildScrollView(
          padding: EdgeInsets.all(horizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.credit_card_outlined,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: (constraints.maxWidth - horizontal * 2).clamp(
                      220,
                      520,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planos e Subscrições',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Escolha o plano ideal para manter o Syscredi ativo e atualizado.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const ActivationContactCard(premium: true),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        _current == 'Trial'
                            ? Icons.pending
                            : Icons.verified_outlined,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: compact ? constraints.maxWidth - 80 : 420,
                        child: Text(
                          _current == 'Trial'
                              ? 'Plano atual: Trial · $_trialDays dias restantes'
                              : 'Plano atual: $_current · $_currentPackage',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (_current != 'Trial')
                        Text(
                          _current == 'Vitalício' ? 'Para sempre' : 'Ativo',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Escolha o seu plano',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final plan in _plans)
                    _PlanCard(
                      plan: plan,
                      current: _current == plan.name,
                      selected: _selected == plan.name,
                      organizationUsers: _organizationUserLimit,
                      width: cardWidth,
                      onTap: () => _choose(plan),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FluentSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => setState(
                        () => _activationExpanded = !_activationExpanded,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline, color: scheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _current == 'Trial'
                                        ? 'Activar plano'
                                        : 'Alterar ou renovar plano',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _activationExpanded
                                        ? 'Insira o código fornecido pelo proprietário para associar a licença à organização.'
                                        : 'A organização já possui um plano ativo. Clique para mostrar a ativação.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => setState(
                                () =>
                                    _activationExpanded = !_activationExpanded,
                              ),
                              icon: Icon(
                                _activationExpanded
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: Text(
                                _activationExpanded ? 'Ocultar' : 'Mostrar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _activationExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _activationCode,
                              maxLength: 300,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'Código de ativação',
                                hintText: 'Cole aqui o código completo',
                                prefixIcon: const Icon(
                                  Icons.assignment_outlined,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: 'Colar código',
                                  onPressed: () async {
                                    final data = await Clipboard.getData(
                                      Clipboard.kTextPlain,
                                    );
                                    final value = data?.text?.trim();
                                    if (value == null || value.isEmpty) {
                                      if (!context.mounted) return;
                                      await showFeedbackDialog(
                                        context,
                                        title: 'Área de transferência vazia',
                                        message:
                                            'Copie primeiro o código gerado pelo Syscredi Activator.',
                                      );
                                      return;
                                    }
                                    _activationCode.text = value;
                                    _activationCode.selection =
                                        TextSelection.collapsed(
                                          offset: value.length,
                                        );
                                  },
                                  icon: const Icon(Icons.document),
                                ),
                              ),
                              onSubmitted: (_) => _activate(),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _activating ? null : _activate,
                                icon: _activating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.verified_outlined),
                                label: Text(
                                  _activating ? 'A validar…' : 'Activar código',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withValues(
                                            alpha: .1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.card_membership_outlined,
                                          color: scheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Identificadores da licença',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Necessários para vincular o plano à organização.',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(
                                              text:
                                                  'Dispositivo: $_deviceId\nOrganização: ${widget.organizationId}',
                                            ),
                                          );
                                          if (!context.mounted) return;
                                          await showFeedbackDialog(
                                            context,
                                            title: 'IDs copiados',
                                            message:
                                                'Os identificadores foram copiados.',
                                            success: true,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.document,
                                          size: 17,
                                        ),
                                        label: const Text('Copiar ambos'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _IdentifierCard(
                                    icon: Icons.card_membership_outlined,
                                    label: 'ID do dispositivo',
                                    value: _deviceId,
                                    onCopy: () => _copyIdentifier(
                                      context,
                                      _deviceId,
                                      'O ID do dispositivo foi copiado.',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _IdentifierCard(
                                    icon: Icons.business_outlined,
                                    label: 'ID da organização',
                                    value: widget.organizationId,
                                    onCopy: () => _copyIdentifier(
                                      context,
                                      widget.organizationId,
                                      'O ID da organização foi copiado.',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Envie estes IDs ao proprietário para gerar o código de ativação.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                height: 1.4,
                                              ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyIdentifier(
    BuildContext context,
    String value,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    await showFeedbackDialog(
      context,
      title: 'ID copiado',
      message: message,
      success: true,
    );
  }
}

class _IdentifierCard extends StatelessWidget {
  const _IdentifierCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String label, value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value.isEmpty ? 'Não disponível' : value,
                  style: TextStyle(
                    color: scheme.primary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .25,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copiar $label',
            onPressed: value.isEmpty ? null : onCopy,
            icon: const Icon(Icons.document, size: 19),
          ),
        ],
      ),
    );
  }
}

class _ActivationLicense {
  const _ActivationLicense(
    this.plan,
    this.expiresAt, {
    required this.package,
    required this.deviceLimit,
  });

  final String plan;
  final DateTime expiresAt;
  final String package;
  final int? deviceLimit;
}

class _Plan {
  const _Plan(this.name, this.price, this.detail, this.icon, this.popular);
  final String name, price, detail;
  final IconData icon;
  final bool popular;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.current,
    required this.selected,
    required this.organizationUsers,
    required this.onTap,
    required this.width,
  });
  final _Plan plan;
  final bool current, selected;
  final int organizationUsers;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = plan.name == 'Vitalício'
        ? const Color(0xffc49322)
        : plan.name == 'Anual'
        ? const Color(0xff168c5b)
        : scheme.primary;
    return SizedBox(
      width: width.clamp(0, 340),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected || current ? accent : scheme.outlineVariant,
            width: selected || current ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(plan.icon, color: accent),
                  const Spacer(),
                  if (plan.popular) _Badge('Mais escolhido', accent),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plan.price,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              Text(
                plan.detail,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              const _Feature('Acesso completo ao Syscredi'),
              const _Feature('Atualizações e suporte'),
              const _Feature('Dados protegidos e auditáveis'),
              const SizedBox(height: 14),
              _PackageLine(
                name: 'Básico',
                detail: '1 dispositivo',
                price: plan.price,
              ),
              const SizedBox(height: 7),
              _PackageLine(
                name: 'Pro',
                detail: '$organizationUsers dispositivos',
                price: _addPrice(plan.price, 459),
                recommended: true,
              ),
              const SizedBox(height: 7),
              _PackageLine(
                name: 'Premium',
                detail: 'Dispositivos ilimitados',
                price: _addPrice(plan.price, 1159),
                premium: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: current ? null : onTap,
                  child: Text(current ? 'Plano atual' : 'Escolher plano'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _addPrice(String value, int surcharge) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    final total = (int.tryParse(digits) ?? 0) + surcharge;
    final formatted = total.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ' ',
    );
    return '$formatted MT';
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 7),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
    ),
  );
}

class _PackageLine extends StatelessWidget {
  const _PackageLine({
    required this.name,
    required this.detail,
    required this.price,
    this.recommended = false,
    this.premium = false,
  });

  final String name, detail, price;
  final bool recommended, premium;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final premiumColor = const Color(0xFFC49322);
    final accent = premium ? premiumColor : scheme.primary;
    final highlighted = recommended || premium;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: highlighted ? 11 : 10,
        vertical: highlighted ? 10 : 9,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withValues(alpha: recommended ? .09 : .10)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? accent.withValues(alpha: recommended ? .78 : .65)
              : scheme.outlineVariant,
          width: recommended ? 1.6 : (premium ? 1.4 : 1),
        ),
        boxShadow: recommended
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: .10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: highlighted ? accent : null,
                      ),
                    ),
                    if (recommended) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Recomendado',
                          style: TextStyle(
                            color: accent,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (premium) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.verified_outlined,
                        size: 14,
                        color: premiumColor,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: highlighted ? accent : scheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
