import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/config.dart';
import '../../features/api/application/session_service.dart';
import '../../features/api/domain/repository.dart';
import '../../features/api/infrastructure/empty_account_repository.dart';
import '../../features/api/infrastructure/guest_repository.dart';
import '../../features/api/infrastructure/supabase_auth_gateway.dart';
import '../../features/api/presentation/session_view_model.dart';

const demoAccountEmail = 'ladans.me@gmail.com';

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
  final emptyRepository = EmptyAccountRepository(() => _profile(auth));
  final repository = _AuthOnlyRepository(
    auth: auth,
    emptyRepository: emptyRepository,
  );
  final session = SessionService(
    auth,
    repository,
    guestRepository: const GuestRepository(),
  );
  await session.restore();
  return AppSession(session);
}

Json _profile(SupabaseAuthGateway auth) {
  final user = auth.client.auth.currentUser;
  return {
    'id': auth.userId ?? 'session-user',
    'name': user?.userMetadata?['name'] ?? 'Utilizador',
    'email': user?.email ?? '',
    'organization_name': user?.userMetadata?['organization_name'] ?? '',
    'role': 'manager',
    'active': true,
  };
}

bool isDemoAccount(String? email) =>
    email?.trim().toLowerCase() == demoAccountEmail;

class _AuthOnlyRepository implements Repository {
  const _AuthOnlyRepository({
    required this.auth,
    required this.emptyRepository,
  });

  final SupabaseAuthGateway auth;
  final EmptyAccountRepository emptyRepository;

  bool get _demo => isDemoAccount(auth.client.auth.currentUser?.email);

  @override
  Future<dynamic> get(String path) async {
    if (!_demo) return emptyRepository.get(path);
    final uri = Uri.parse(path);
    if (uri.path == '/risk-scores') {
      return [
        for (final (index, item) in <(String, int, int, String, bool)>[
          ('Adelino Armando de Sousa', 564000, 0, 'Baixo', false),
          ('Júlio Custódio', 1820000, 45, 'Alto', false),
          ('Elisabete Celeste Luis Piwalo', 750000, 18, 'Moderado', true),
          ('Armando Manuel Antonio Munhangange', 1250000, 8, 'Moderado', false),
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
    if (uri.path == '/audit') {
      return const <Json>[
        {
          'table': 'usuarios',
          'action': 'Login',
          'created_at': '2026-09-11T18:07:29',
          'actor_name': 'Naveia Muaquiua João',
          'entity_id': '0',
          'description': 'Login',
        },
      ];
    }
    if (uri.path == '/dashboard') {
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
    return emptyRepository.get(path);
  }

  @override
  Future<dynamic> publicWrite(String method, String path, Json body) async {
    if (path != '/organizations/register') return <String, dynamic>{};
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
  Future<Uint8List> bytes(String path) => emptyRepository.bytes(path);

  @override
  Future<String> cancel(PendingWrite operation) =>
      emptyRepository.cancel(operation);

  @override
  void close() => emptyRepository.close();

  @override
  Future<List<Json>> page(String path, {int offset = 0, int limit = 50}) =>
      emptyRepository.page(path, offset: offset, limit: limit);

  @override
  Future<List<PendingWrite>> pending() => emptyRepository.pending();

  @override
  Future<dynamic> retry(PendingWrite operation) =>
      emptyRepository.retry(operation);

  @override
  Future<dynamic> write(String method, String path, Json body) =>
      emptyRepository.write(method, path, body);
}
