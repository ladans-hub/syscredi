import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config.dart';
import '../../features/api/application/session_service.dart';
import '../../features/api/domain/repository.dart';
import '../../features/api/infrastructure/supabase_auth_gateway.dart';
import '../../features/api/presentation/session_view_model.dart';

Future<AppSession> connectAuthOnly() async {
  final config = AppConfig.environment;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );
  final auth = SupabaseAuthGateway(Supabase.instance.client);
  final session = SessionService(auth, _MockRepository(auth));
  await session.restore();
  return AppSession(session);
}

class _MockRepository implements Repository {
  _MockRepository(this.auth);
  final SupabaseAuthGateway auth;

  @override
  Future<dynamic> get(String path) async {
    if (path == '/dashboard') {
      return {
        'clients': 248,
        'pending_requests': 18,
        'outstanding_cents': 186450000,
        'overdue_cents': 12750000,
        'disbursed_cents': 64280000,
        'collection_rate': 87,
        'monthly_revenue': [42, 48, 44, 58, 62, 70, 76, 82, 78, 91, 96, 104],
      };
    }
    return {
      'id': auth.userId ?? 'mock-user',
      'name':
          auth.client.auth.currentUser?.userMetadata?['name'] ?? 'Utilizador',
      'email': auth.client.auth.currentUser?.email ?? '',
      'role': 'manager',
      'active': true,
    };
  }

  @override
  Future<List<Json>> page(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async => [];
  @override
  Future<List<PendingWrite>> pending() async => [];
  @override
  Future<Uint8List> bytes(String path) async => Uint8List(0);
  @override
  Future<dynamic> write(String method, String path, Json body) async => {};
  @override
  Future<dynamic> publicWrite(String method, String path, Json body) async {
    if (path != '/organizations/register') return {};
    final result = await auth.client.auth.signUp(
      email: '${body['managerEmail']}'.trim(),
      password: '${body['password']}',
      data: {'name': '${body['managerName']}'.trim()},
    );
    final refreshToken = result.session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiFailure(
        'Confirme o email de acesso antes de entrar.',
        status: 202,
      );
    }
    return {
      'session': {'refresh_token': refreshToken},
    };
  }

  @override
  Future<dynamic> retry(PendingWrite operation) async => {};
  @override
  Future<String> cancel(PendingWrite operation) async => operation.key;
  @override
  void close() {}
}
