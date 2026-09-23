import 'dart:typed_data';

import '../domain/repository.dart';

class GuestRepository implements Repository {
  const GuestRepository();

  static const _profile = <String, dynamic>{
    'id': 'guest',
    'name': 'Visitante',
    'email': 'guest@syscredi.local',
    'role': 'operator',
    'active': true,
    'guest': true,
  };

  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    return switch (uri.path) {
      '/me' => Map<String, dynamic>.from(_profile),
      '/dashboard' => <String, dynamic>{
        'clients': 0,
        'pending_requests': 0,
        'outstanding_cents': 0,
        'overdue_cents': 0,
        'disbursed_this_month_cents': 0,
        'collected_this_month_cents': 0,
        'currencies': <dynamic>[],
        'demo': true,
      },
      '/notifications' || '/search' => <dynamic>[],
      _ => <dynamic>[],
    };
  }

  Never _readOnly() => throw const ApiFailure(
    'O modo visitante é somente leitura. Entre para realizar operações.',
    status: 403,
  );

  @override
  Future<Uint8List> bytes(String path) async => _readOnly();

  @override
  Future<String> cancel(PendingWrite operation) async => _readOnly();

  @override
  void close() {}

  @override
  Future<List<Json>> page(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async => <Json>[];

  @override
  Future<List<PendingWrite>> pending() async => <PendingWrite>[];

  @override
  Future<dynamic> publicWrite(String method, String path, Json body) async =>
      _readOnly();

  @override
  Future<dynamic> retry(PendingWrite operation) async => _readOnly();

  @override
  Future<dynamic> write(String method, String path, Json body) async =>
      _readOnly();
}
