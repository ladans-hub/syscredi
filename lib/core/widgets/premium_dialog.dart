import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;

/// Shared Fluent dialog shell for detail, review and edit experiences.
/// Header and command footer stay visible while long content scrolls.
class PremiumDialog extends StatelessWidget {
  const PremiumDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    this.subtitle,
    this.icon = FluentIcons.document,
    this.width = 760,
    this.showClose = true,
    super.key,
  });
  final Widget title, content;
  final List<Widget> actions;
  final String? subtitle;
  final IconData icon;
  final double width;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: colors.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle(
                          style: theme.textTheme.titleLarge!.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                          child: title,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      tooltip: 'Fechar janela',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(FluentIcons.clear, size: 16),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              ),
            ),
            if (actions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  border: Border(top: BorderSide(color: colors.outlineVariant)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DetailFields extends StatelessWidget {
  const DetailFields({required this.fields, super.key});
  final List<(String, String)> fields;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 500 ? 2 : 1;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (label, value) in fields)
            SizedBox(
              width: (constraints.maxWidth - (columns - 1) * 16) / columns,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SelectableText(
                      value.isEmpty ? '—' : value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
