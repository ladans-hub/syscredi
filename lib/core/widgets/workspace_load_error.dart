import 'package:flutter/material.dart';

import '../../features/api/domain/repository.dart';
import 'equal_button_group.dart';

/// A failed initial load must remain recoverable without restarting the app.
class WorkspaceLoadError extends StatelessWidget {
  const WorkspaceLoadError({
    required this.error,
    required this.onRetry,
    this.onLogout,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback? onLogout;

  String get message {
    final failure = error;
    if (failure is ApiFailure) {
      if (failure.status == 401) {
        return 'A sua sessão expirou. Termine a sessão e entre novamente.';
      }
      if (failure.status == 403) {
        return 'A sua conta não tem acesso a estes dados. Contacte o administrador.';
      }
      return failure.message;
    }
    return 'Não foi possível preparar o seu espaço. Verifique a ligação e tente novamente.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 34),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              EqualButtonGroup(
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                  if (onLogout != null)
                    OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Terminar sessão'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
