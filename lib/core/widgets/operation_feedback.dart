import 'dart:async';
import 'package:flutter/material.dart' hide Icons;
import '../../app/theme/fluent_icons_compat.dart';
import 'dart:math' as math;
import '../../app/theme/app_theme.dart';

enum FeedbackKind { success, info, error }

Future<bool> runWithFeedback(
  BuildContext context,
  Future<void> Function() operation, {
  String title = 'A processar operação',
  String successTitle = 'Operação concluída',
  String successMessage = 'A operação foi confirmada pelo servidor.',
  FutureOr<void> Function()? onSuccess,
}) async {
  if (!context.mounted) return false;
  _showAnimatedDialog<void>(
    context,
    const _ProgressDialog(),
    dismissible: false,
  );
  try {
    await operation();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return true;
    await onSuccess?.call();
    await _showAnimatedDialog<void>(
      context,
      _ResultDialog(
        kind: FeedbackKind.success,
        title: successTitle,
        message: successMessage,
      ),
    );
    return true;
  } catch (error) {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!context.mounted) return false;
    await _showAnimatedDialog<void>(
      context,
      _ResultDialog(
        kind: FeedbackKind.error,
        title: 'Operação não confirmada',
        message: error.toString().replaceFirst('Exception: ', ''),
      ),
    );
    return false;
  }
}

Future<void> showFeedbackDialog(
  BuildContext context, {
  required String message,
  String title = 'Informação',
  bool? success,
  FeedbackKind? kind,
}) async {
  if (!context.mounted) return;
  final lower = message.toLowerCase();
  final failure =
      lower.contains('não') ||
      lower.contains('inválid') ||
      lower.contains('erro') ||
      lower.contains('falha') ||
      lower.contains('impossível') ||
      lower.startsWith('exception') ||
      lower.startsWith('stateerror');
  final inferredKind =
      kind ??
      (success == true
          ? FeedbackKind.success
          : success == false || failure
          ? FeedbackKind.error
          : FeedbackKind.info);
  await _showAnimatedDialog<void>(
    context,
    _ResultDialog(kind: inferredKind, title: title, message: message),
  );
}

Future<T?> _showAnimatedDialog<T>(
  BuildContext context,
  Widget child, {
  bool dismissible = false,
}) => showGeneralDialog<T>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: dismissible,
  barrierLabel: 'Fechar',
  barrierColor: Colors.black.withValues(alpha: .48),
  transitionDuration: const Duration(milliseconds: 240),
  pageBuilder: (_, _, _) => child,
  transitionBuilder: (_, animation, secondary, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: .92, end: 1).animate(curved),
        child: child,
      ),
    );
  },
);

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    content: const SizedBox(
      width: 320,
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: SyscrediProgressIndicator()),
          SizedBox(width: 18),
          Expanded(child: Text('A aguardar confirmação segura do servidor…')),
        ],
      ),
    ),
  );
}

class _ResultDialog extends StatefulWidget {
  const _ResultDialog({
    required this.kind,
    required this.title,
    required this.message,
  });
  final FeedbackKind kind;
  final String title, message;
  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
    reverseDuration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> close() async {
    await controller.reverse();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = switch (widget.kind) {
      FeedbackKind.success => const Color(0xFF31E29A),
      FeedbackKind.info => const Color(0xFFFFA62B),
      FeedbackKind.error => const Color(0xFFFF5D63),
    };
    final icon = switch (widget.kind) {
      FeedbackKind.success => Icons.check_rounded,
      FeedbackKind.info => Icons.priority_high_rounded,
      FeedbackKind.error => Icons.close_rounded,
    };
    final panel = dark ? const Color(0xFF101817) : Colors.white;
    final text = dark ? Colors.white : const Color(0xFF152739);
    final muted = dark ? const Color(0xFFB7C4C2) : const Color(0xFF657789);
    final palette = brandPalette.value;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          decoration: BoxDecoration(
            color: panel,
            gradient: LinearGradient(
              colors: dark
                  ? [
                      Color.alphaBlend(
                        palette.primary.withValues(alpha: .18),
                        panel,
                      ),
                      Color.alphaBlend(
                        palette.secondary.withValues(alpha: .16),
                        const Color(0xFF0D1213),
                      ),
                    ]
                  : [
                      Color.alphaBlend(
                        palette.primary.withValues(alpha: .07),
                        Colors.white,
                      ),
                      Color.alphaBlend(
                        palette.secondary.withValues(alpha: .06),
                        Colors.white,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: palette.primary.withValues(alpha: dark ? .48 : .30),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .42 : .18),
                blurRadius: 38,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 34, 22, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: controller,
                      builder: (_, child) => Transform.rotate(
                        angle:
                            math.sin(controller.value * math.pi * 2.4) * .055,
                        child: Transform.scale(
                          scale: Curves.elasticOut.transform(
                            controller.value.clamp(0, 1),
                          ),
                          child: child,
                        ),
                      ),
                      child: _FeedbackIcon(icon: icon, accent: accent),
                    ),
                    const SizedBox(height: 17),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: text,
                        fontSize: 21,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 17),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: brandPalette.value.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: close,
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackIcon extends StatelessWidget {
  const _FeedbackIcon({required this.icon, required this.accent});
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Container(
    width: 77,
    height: 77,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: accent,
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .28),
          blurRadius: 16,
          spreadRadius: 5,
        ),
        BoxShadow(
          color: accent.withValues(alpha: .18),
          blurRadius: 0,
          spreadRadius: 9,
        ),
      ],
      border: Border.all(color: Colors.white.withValues(alpha: .18), width: 2),
    ),
    child: Icon(icon, color: Colors.white, size: 49),
  );
}
