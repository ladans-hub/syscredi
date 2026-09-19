import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repository.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  bool get hasSession => client.auth.currentSession != null;
  @override
  Stream<bool> get sessionChanges => client.auth.onAuthStateChange.map(
    (event) => event.event != AuthChangeEvent.signedOut && hasSession,
  );
  @override
  Future<void> login(String email, String password) async {
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException {
      throw const ApiFailure(
        'Não foi possível entrar. Verifique o email, a palavra-passe e a ligação.',
        status: 401,
      );
    }
  }

  @override
  Future<void> recoverPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (error) {
      throw ApiFailure(
        error.message,
        status: int.tryParse(error.statusCode ?? '') ?? 400,
      );
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    try {
      await client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw ApiFailure(
        error.message,
        status: int.tryParse(error.statusCode ?? '') ?? 400,
      );
    }
  }

  @override
  Future<void> register(String name, String email, String password) async {
    try {
      final result = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      if (result.session == null) {
        throw const ApiFailure(
          'Confirme o email de acesso antes de entrar.',
          status: 202,
        );
      }
    } on AuthException catch (error) {
      throw ApiFailure(
        error.message,
        status: int.tryParse(error.statusCode ?? '') ?? 400,
      );
    }
  }

  @override
  Future<void> adoptSession(String refreshToken) async {
    try {
      await client.auth.setSession(refreshToken);
    } on AuthException catch (error) {
      throw ApiFailure(error.message, status: 401);
    }
  }

  @override
  Future<void> refreshToken() async {
    try {
      await client.auth.refreshSession();
    } on AuthException catch (error) {
      final status = int.tryParse(error.statusCode ?? '');
      throw ApiFailure(
        status != null && status >= 500
            ? 'Autenticação indisponível.'
            : 'Sessão expirada. Entre novamente.',
        status: status != null && status >= 500 ? 503 : 401,
      );
    }
  }

  @override
  Future<String?> accessToken() async {
    if (client.auth.currentSession?.isExpired == true) await refreshToken();
    return client.auth.currentSession?.accessToken;
  }

  @override
  Future<void> logout() => client.auth.signOut(scope: SignOutScope.local);
}
