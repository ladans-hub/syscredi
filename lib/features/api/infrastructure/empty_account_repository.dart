import 'dart:typed_data';

import '../domain/repository.dart';

class EmptyAccountRepository implements Repository {
  const EmptyAccountRepository(this.profile);

  final Json Function() profile;

  @override
  Future<dynamic> get(String path) async {
    final uri = Uri.parse(path);
    return switch (uri.path) {
      '/me' => profile(),
      '/dashboard' => <String, dynamic>{
        'clients': 0,
        'pending_requests': 0,
        'outstanding_cents': 0,
        'overdue_cents': 0,
        'disbursed_cents': 0,
        'collection_rate': 0,
        'monthly_revenue': <int>[],
      },
      '/organization-settings' ||
      '/notifications' ||
      '/search' ||
      '/organizations/mine' => <dynamic>[],
      _ => <dynamic>[],
    };
  }

  @override
  Future<Uint8List> bytes(String path) async => Uint8List(0);

  @override
  Future<String> cancel(PendingWrite operation) async => operation.key;

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
      <String, dynamic>{};

  @override
  Future<dynamic> retry(PendingWrite operation) async => <String, dynamic>{};

  @override
  Future<dynamic> write(String method, String path, Json body) async =>
      <String, dynamic>{};
}
