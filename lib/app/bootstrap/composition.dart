import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../config/config.dart';
import '../../features/api/application/session_service.dart';
import '../../features/api/infrastructure/http_repository.dart';
import '../../features/api/infrastructure/guest_repository.dart';
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
  const operationalStorage = DeviceOperationalStore();
  final authStorage = SecureAuthStorage(
    storage,
    'syscredi.${config.scope}.session',
  );
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: authStorage,
      pkceAsyncStorage: SecurePkceStorage(storage, config.scope),
      detectSessionInUri: true,
    ),
  );
  final auth = SupabaseAuthGateway(
    Supabase.instance.client,
    passwordRecoveryUrl: config.effectivePasswordRecoveryUrl,
    localStorage: authStorage,
  );
  final repository = ApiClient(
    baseUrl: config.apiUrl,
    scope: config.scope,
    store: operationalStorage,
    userId: () => auth.userId,
    accessToken: auth.accessToken,
    refreshToken: auth.refreshToken,
  );
  final service = SessionService(
    auth,
    repository,
    guestRepository: const GuestRepository(),
  );
  await service.restore();
  return AppSession(service);
}
