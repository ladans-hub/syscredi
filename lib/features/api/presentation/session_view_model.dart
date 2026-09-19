import 'dart:async';
import 'package:flutter/foundation.dart';
import '../application/session_service.dart';
import '../domain/repository.dart';

abstract class WorkspaceSession extends ChangeNotifier {
  Repository get api;
  Json? get profile;
  bool get manager => profile?['role'] == 'manager';
  bool get analyst => ['manager', 'analyst'].contains(profile?['role']);
  Future<void> updatePassword(String password);
  Future<void> verify();
  Future<void> logout();
}

class AppSession extends WorkspaceSession {
  AppSession(this.service) {
    _subscription = service.changes.listen((_) => notifyListeners());
  }
  final SessionService service;
  StreamSubscription<void>? _subscription;
  @override
  Repository get api => service.repository;
  @override
  Json? get profile => service.profile;
  String? get error => service.error;
  void enterGuest() => service.enterGuest();

  Future<void> login(String email, String password) =>
      service.login(email, password);
  Future<void> recoverPassword(String email) => service.recoverPassword(email);
  @override
  Future<void> updatePassword(String password) =>
      service.updatePassword(password);
  Future<void> register(
    String name,
    String email,
    String password,
    String organizationName,
  ) => service.register(name, email, password, organizationName);

  @override
  Future<void> verify() => service.verify();
  @override
  Future<void> logout() => service.logout();
  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    unawaited(service.dispose());
    super.dispose();
  }
}
