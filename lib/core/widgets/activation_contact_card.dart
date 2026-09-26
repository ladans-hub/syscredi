import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivationContactCard extends StatelessWidget {
  const ActivationContactCard({
    this.compact = false,
    this.premium = false,
    super.key,
  });

  static const phone = '+258 84 055 29 30';
  static const _phoneDigits = '258840552930';
  final bool compact;
  final bool premium;

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent(
      'Olá LADANS, preciso de uma licença de ativação para o Syscredi.',
    );
    final native = Uri.parse(
      'whatsapp://send?phone=$_phoneDigits&text=$message',
    );
    final web = Uri.parse('https://wa.me/$_phoneDigits?text=$message');
    if (await launchUrl(native, mode: LaunchMode.externalApplication)) return;
    if (await launchUrl(web, mode: LaunchMode.externalApplication)) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    const whatsappGreen = Color(0xFF16A816);
    final premiumForeground = dark ? Colors.white : const Color(0xFF17352D);
    final premiumMuted = dark
        ? const Color(0xFFB8CFC7)
        : const Color(0xFF60736D);
    final premiumPhone = dark
        ? const Color(0xFFB9F5CB)
        : const Color(0xFF137A43);
    final details = Row(
      children: [
        Container(
          width: compact ? 42 : 52,
          height: compact ? 42 : 52,
          padding: EdgeInsets.all(compact ? 9 : 11),
          decoration: BoxDecoration(
            color: premium
                ? (dark
                      ? Colors.white.withValues(alpha: .92)
                      : const Color(0xFFF7FFFA))
                : whatsappGreen.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(compact ? 11 : 13),
            border: Border.all(
              color: premium
                  ? (dark
                        ? Colors.white.withValues(alpha: .55)
                        : const Color(0xFFBFE6CD))
                  : whatsappGreen.withValues(alpha: .16),
            ),
            boxShadow: premium
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: dark ? 14 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Image.asset('assets/images/whatsapp.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Precisa do seu código de ativação?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13 : 15,
                  color: premium ? premiumForeground : null,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Contacte a LADANS para ativar o Syscredi.',
                style: TextStyle(
                  color: premium ? premiumMuted : scheme.onSurfaceVariant,
                  fontSize: compact ? 10.5 : 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phone,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 13 : 15,
                  color: premium ? premiumPhone : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final button = FilledButton(
      onPressed: () => _openWhatsApp(context),
      child: const Text('Contactar'),
    );
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: premium ? null : scheme.surfaceContainerLow,
        gradient: premium
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF12382F), Color(0xFF0C211E)]
                    : const [
                        Color(0xFFFFFFFF),
                        Color(0xFFF3FAF6),
                        Color(0xFFECF7F0),
                      ],
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: premium
              ? (dark
                    ? const Color(0xFF21A56B).withValues(alpha: .55)
                    : const Color(0xFFB8DFC7))
              : scheme.primary.withValues(alpha: .24),
        ),
        boxShadow: [
          BoxShadow(
            color: premium
                ? (dark
                      ? const Color(0xFF09211A).withValues(alpha: .24)
                      : const Color(0xFF244F3C).withValues(alpha: .10))
                : scheme.shadow.withValues(alpha: .055),
            blurRadius: premium ? (dark ? 22 : 18) : 12,
            offset: const Offset(0, 6),
          ),
          if (premium && !dark)
            BoxShadow(
              color: Colors.white.withValues(alpha: .85),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                details,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: button),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 14),
              button,
            ],
          );
        },
      ),
    );
  }
}
