import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config.dart';
import '../../features/api/application/session_service.dart';
import '../../features/api/domain/repository.dart';
import '../../features/api/infrastructure/supabase_auth_gateway.dart';
import '../../features/api/infrastructure/guest_repository.dart';
import '../../features/api/presentation/session_view_model.dart';

Future<AppSession> connectAuthOnly() async {
  final config = AppConfig.environment;
  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.publishableKey,
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: true),
  );
  final auth = SupabaseAuthGateway(
    Supabase.instance.client,
    passwordRecoveryUrl: config.effectivePasswordRecoveryUrl,
  );
  final session = SessionService(
    auth,
    _MockRepository(auth),
    guestRepository: const GuestRepository(),
  );
  await session.restore();
  return AppSession(session);
}

class _MockRepository implements Repository {
  _MockRepository(this.auth);
  final SupabaseAuthGateway auth;

  @override
  Future<dynamic> get(String path) async {
    if (Uri.parse(path).path == '/risk-scores') {
      return [
        for (final (index, item) in <(String, int, int, String, bool)>[
          ('Adelino Armando de Sousa', 564000, 0, 'Baixo', false),
          ('Júlio Custódio', 1820000, 45, 'Alto', false),
          ('Elisabete Celeste Luis Piwalo', 750000, 18, 'Moderado', true),
          ('Armando Manuel Antonio Munhangane', 1250000, 8, 'Moderado', false),
          ('Francisco Adelino Rui', 980000, 96, 'Alto', false),
          ('Celeste António', 2100000, 65, 'Alto', true),
          ('Ana Maria João', 1600000, 0, 'Baixo', false),
        ].indexed)
          {
            'id': 'risk-demo-$index',
            'client_id': 'CL-${301 + index}',
            'client_name': item.$1,
            'loan_id': 'CR-2026-${303 - index}',
            'balance_cents': item.$2,
            'days_past_due': item.$3,
            'band': item.$4,
            'restructured': item.$5,
            'officer_name': 'Equipa de crédito',
            'assessed_at': '2026-09-20',
            'demo': true,
          },
      ];
    }
    if (Uri.parse(path).path == '/audit') {
      const naveia = 'Naveia Muaquiua João';
      const loide = 'Loide Janeth Ligia Salvado Roque de Aguiar';
      const events = [
        [
          'receber',
          'Reembolsou um crédito',
          '18:42:38',
          naveia,
          '303',
          'ADELINO ARMANDO DE SOUSA',
        ],
        [
          'emprestimos_simulados',
          'Inserção',
          '18:11:45',
          naveia,
          '1',
          'Simulação',
        ],
        ['usuarios', 'Login', '18:07:29', naveia, '0', 'Login'],
        ['usuarios', 'Logout', '18:07:26', naveia, '0', 'Logout'],
        ['usuarios', 'Login', '17:56:07', naveia, '0', 'Login'],
        ['usuarios', 'Logout', '17:55:57', loide, '0', 'Logout'],
        [
          'emprestimos',
          'Submissão',
          '17:55:40',
          loide,
          '303',
          'CRÉDITO: 303 para aprovação',
        ],
        ['usuarios', 'Login', '17:54:29', loide, '0', 'Login'],
        ['usuarios', 'Logout', '17:54:24', naveia, '0', 'Logout'],
        [
          'emprestimos',
          'Iniciou um crédito',
          '17:37:26',
          naveia,
          '303',
          'CRÉDITO: 303 · CLIENTE: ADELINO ARMANDO DE SOUSA',
        ],
      ];
      return [
        for (final e in events)
          {
            'table': e[0],
            'action': e[1],
            'created_at': '2026-09-11T${e[2]}',
            'actor_name': e[3],
            'entity_id': e[4],
            'description': e[5],
          },
      ];
    }
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
      'id': auth.userId ?? 'session-user',
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
      data: {
        'name': '${body['managerName']}'.trim(),
        'organization_name': '${body['organizationName']}'.trim(),
        'email_sender_name': '${body['organizationName']}'.trim().isEmpty
            ? 'Syscredi'
            : '${body['organizationName']}'.trim(),
      },
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
