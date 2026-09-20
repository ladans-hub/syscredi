import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../../features/api/application/session_service.dart';
import '../../features/api/infrastructure/http_repository.dart';
import '../../features/api/infrastructure/secure_store.dart';
import '../../features/api/infrastructure/supabase_auth_gateway.dart';
import '../../features/api/presentation/session_view_model.dart';

Future<AppSession> connect(AppConfig config) async {
  // Keep the selected endpoint observable in debug logs when diagnosing a
  // stale desktop bundle; no credential or token is emitted.
  assert(() {
    debugPrint('Syscredi API endpoint configured: ${config.apiUrl}');
    return true;
  }());
  final problem = config.validate();
  if (problem != null) throw StateError(problem);
  const storage = DeviceSecretStore();
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureAuthStorage(
        storage,
        'syscredi.${config.scope}.session',
      ),
      pkceAsyncStorage: SecurePkceStorage(storage, config.scope),
      detectSessionInUri: false,
    ),
  );
  final auth = SupabaseAuthGateway(Supabase.instance.client);
  final repository = ApiClient(
    baseUrl: config.apiUrl,
    scope: config.scope,
    store: storage,
    userId: () => auth.userId,
    accessToken: auth.accessToken,
    refreshToken: auth.refreshToken,
  );
  final service = SessionService(auth, repository);
  await service.restore();
  return AppSession(service);
}
