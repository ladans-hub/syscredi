import 'dart:async';
import '../domain/repository.dart';

class SessionService {
  SessionService(this.auth, this.repository, {Repository? guestRepository})
    : _guestRepository = guestRepository {
    _subscription = auth.sessionChanges.listen(
      (valid) {
        if (!valid) {
          profile = null;
          _changes.add(null);
        }
      },
      onError: (Object _) {
        profile = null;
        error = 'Não foi possível renovar a sessão. Entre novamente.';
        _changes.add(null);
      },
    );
    _passwordRecoverySubscription = auth.passwordRecoveryChanges.listen((_) {
      passwordRecovery = true;
      profile = null;
      _changes.add(null);
    });
  }
  final AuthGateway auth;
  final Repository repository;
  final Repository? _guestRepository;
  Repository get activeRepository =>
      profile?['guest'] == true ? (_guestRepository ?? repository) : repository;
  final _changes = StreamController<void>.broadcast(sync: true);
  StreamSubscription<bool>? _subscription;
  StreamSubscription<bool>? _passwordRecoverySubscription;
  Stream<void> get changes => _changes.stream;
  Json? profile;
  bool passwordRecovery = false;
  String? error;
  String? _registrationKey;
  static int _registrationSequence = 0;
  Future<void> restore() async {
    if (!auth.hasSession) return;
    try {
      await verify();
    } catch (_) {
      error = 'Não foi possível recuperar o acesso. Entre novamente.';
    }
  }

  void enterGuest() {
    error = null;
    profile = const {
      'id': 'guest',
      'name': 'Visitante',
      'email': 'guest@syscredi.local',
      'role': 'operator',
      'active': true,
      'guest': true,
    };
    _changes.add(null);
  }

  Future<void> login(String email, String password) async {
    error = null;
    await auth.login(email, password);
    await verify();
  }

  Future<void> recoverPassword(String email) async {
    final value = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      throw const ApiFailure('Indique um email profissional válido.');
    }
    await auth.recoverPassword(value);
  }

  Future<void> updatePassword(String password) async {
    if (password.trim().length < 8) {
      throw const ApiFailure(
        'A palavra-passe deve ter pelo menos 8 caracteres.',
      );
    }
    await auth.updatePassword(password.trim());
    passwordRecovery = false;
    await auth.logout();
    profile = null;
    _changes.add(null);
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String? organizationName,
  ) async {
    final operationId = _registrationKey ??= _newRegistrationKey();
    final slug = 'org-${operationId.replaceAll('-', '').substring(0, 16)}';
    late final dynamic result;
    try {
      result = await repository.publicWrite('POST', '/organizations/register', {
        'managerName': name.trim(),
        'managerEmail': email.trim(),
        'organizationName': (organizationName ?? name).trim(),
        'slug': slug,
        'password': password,
        'clientOperationId': operationId,
      });
    } on ApiFailure catch (error) {
      final detail = error.message.toLowerCase();
      if (detail.contains('already') ||
          detail.contains('registered') ||
          detail.contains('already registered')) {
        throw const ApiFailure(
          'Este email já possui uma conta de acesso. Entre com essa conta ou utilize outro email profissional.',
          status: 409,
        );
      }
      rethrow;
    }
    final session = Map<String, dynamic>.from(result['session'] as Map);
    final refreshToken = '${session['refresh_token'] ?? ''}';
    if (refreshToken.isEmpty) {
      throw const ApiFailure('Sessão de acesso não devolvida.');
    }
    await auth.adoptSession(refreshToken);
    await verify();
    _registrationKey = null;
  }

  String _newRegistrationKey() {
    final timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toRadixString(16);
    final sequence = (++_registrationSequence).toRadixString(16);
    final tail = '$timestamp$sequence'.padLeft(12, '0');
    return '00000000-0000-4000-8000-${tail.substring(tail.length - 12)}';
  }

  Future<void> verify() async {
    if (profile?['guest'] == true) return;
    try {
      final current = Map<String, dynamic>.from(await repository.get('/me'));
      if (!['operator', 'analyst', 'manager'].contains(current['role']) ||
          current['active'] != true) {
        throw const ApiFailure('Perfil sem acesso.', status: 403);
      }
      final changed =
          profile?['role'] != current['role'] ||
          profile?['id'] != current['id'];
      profile = current;
      error = null;
      if (changed) _changes.add(null);
    } on ApiFailure catch (failure) {
      if ([401, 403].contains(failure.status)) {
        profile = null;
        error = failure.message;
        _changes.add(null);
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    if (profile?['guest'] != true) await auth.logout();
    profile = null;
    _changes.add(null);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _passwordRecoverySubscription?.cancel();
    repository.close();
    await _changes.close();
  }
}
