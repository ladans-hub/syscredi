import 'package:flutter/material.dart' hide Icons;
import '../theme/design_tokens.dart';
import '../theme/app_theme.dart';
import '../config/config.dart';
import 'composition.dart';
import 'auth_only_session.dart';
import '../../features/api/presentation/session_view_model.dart';
import '../../features/api/presentation/workspace.dart';
import '../../features/auth/presentation/login_page.dart';

class Root extends StatefulWidget {
  const Root({this.onTheme, super.key});
  final ValueChanged<ThemeMode>? onTheme;
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  late Future<AppSession> connection;
  AppSession? session;
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    connection =
        (AppConfig.dataLayerEnabled
                ? connect(AppConfig.environment)
                : connectAuthOnly())
            .then((value) {
              session = value;
              return value;
            });
  }

  @override
  void dispose() {
    session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppSession>(
    future: connection,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _ConnectionError(
          error: snapshot.error!,
          onRetry: () => setState(_connect),
        );
      }
      if (!snapshot.hasData) {
        return const _ConnectionProgress();
      }
      final session = snapshot.data!;
      assert(() {
        debugPrint('SysCredi auth screen: callback=${session.profile == null}');
        return true;
      }());
      return ListenableBuilder(
        listenable: session,
        builder: (context, _) => session.profile == null
            ? LoginPage(
                login: session.login,
                recoverPassword: session.recoverPassword,
                register: session.register,
                onAuthenticated: (_) {},
              )
            : Workspace(
                key: ValueKey(
                  '${session.profile!['id']}:${session.profile!['role']}',
                ),
                session: session,
                onTheme: widget.onTheme,
              ),
      );
    },
  );
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentSystemIcons.error, size: 52),
              const SizedBox(height: 18),
              const Text(
                'Não foi possível ligar ao SysCredi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(FluentSystemIcons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ConnectionProgress extends StatelessWidget {
  const _ConnectionProgress();
  @override
  Widget build(BuildContext context) => const PremiumProcessingScreen(
    title: 'A ligar ao servidor seguro…',
    subtitle: 'A validar a sua sessão e a organização.',
  );
}
