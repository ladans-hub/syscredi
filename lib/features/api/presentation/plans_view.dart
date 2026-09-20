import 'package:flutter/material.dart' hide Icons;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/fluent_icons_compat.dart';
import '../../../app/theme/fluent_design.dart';
import '../../../core/widgets/operation_feedback.dart';

class PlansView extends StatefulWidget {
  const PlansView({super.key});

  @override
  State<PlansView> createState() => _PlansViewState();
}

class _PlansViewState extends State<PlansView> {
  String? _selected;
  String _current = 'Trial';
  int _trialDays = 14;
  final _activationCode = TextEditingController();
  String _deviceId = const Uuid().v4().toUpperCase();
  bool _activating = false;

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
  }

  @override
  void dispose() {
    _activationCode.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('syscredi.device.id');
    final id = saved ?? const Uuid().v4();
    if (saved == null) await prefs.setString('syscredi.device.id', id);
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
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() => _activating = false);
    await showFeedbackDialog(
      context,
      title: 'Código recebido',
      message: 'A validação será concluída pelo servidor.',
      success: true,
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
      setState(() {
        _current = plan.name;
        _trialDays = 0;
      });
      await showFeedbackDialog(
        context,
        title: 'Plano activado',
        message: 'Plano ${plan.name} activado com sucesso.',
        success: true,
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
                              : 'Plano atual: $_current',
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
                      width: cardWidth,
                      onTap: () => _choose(plan),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              FluentSurface(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activar plano',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Insira o código UUID fornecido pelo proprietário para associar a licença a este dispositivo.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _activationCode,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9|.\-]'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código de ativação',
                        hintText: 'Cole aqui o código UUID',
                        prefixIcon: Icon(Icons.assignment_outlined),
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
                    Text(
                      'ID do dispositivo',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SelectableText(
                            _deviceId,
                            style: TextStyle(
                              color: scheme.primary,
                              fontFamily: 'monospace',
                              letterSpacing: .4,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copiar ID do dispositivo',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: _deviceId),
                            );
                            if (mounted) {
                              await showFeedbackDialog(
                                context,
                                title: 'ID copiado',
                                message: 'O ID do dispositivo foi copiado.',
                                success: true,
                              );
                            }
                          },
                          icon: const Icon(Icons.document),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Envie este ID ao proprietário para gerar o código de ativação.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
    required this.onTap,
    required this.width,
  });
  final _Plan plan;
  final bool current, selected;
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
