import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import '../domain/repository.dart';

class ReliableRepository implements Repository {
  ReliableRepository({
    required this.transport,
    required this.scope,
    required this.store,
    required this.userId,
    required this.newKey,
  });
  final Transport transport;
  final String scope;
  final SecretStore store;
  final String? Function() userId;
  final String Function() newKey;

  bool _writing = false;
  int _cacheEpoch = 0;

  /// Makes all previously cached GET responses unreachable. The next refresh
  /// must come from the API (or fail visibly) instead of restoring stale data.
  void clearReadCache() => _cacheEpoch++;
  String _key(String actor) => 'syscredi.$scope.pending.$actor';
  @override
  Future<List<PendingWrite>> pending() async {
    final actor = userId();
    if (actor == null) return [];
    final raw = await store.read(_key(actor));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((j) => PendingWrite.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<void> _save(String actor, List<PendingWrite> rows) => store.write(
    _key(actor),
    jsonEncode(rows.map((r) => r.toJson()).toList()),
  );
  @override
  Future<dynamic> get(String path) async {
    final cacheKey = _cacheKey(path);
    try {
      final raw = await transport.request('GET', path);
      final result = raw is Map && raw['data'] is List ? raw['data'] : raw;
      developer.log(
        'GET $path -> ${result.runtimeType}${result is List ? ' (${result.length})' : ''}',
        name: 'syscredi.api',
      );
      // The API is authoritative. Cache only confirmed responses for
      // rendering; writes always invalidate the affected resource cache.
      await store.write(cacheKey, jsonEncode(result));
      return result;
    } on ApiFailure catch (error) {
      developer.log('GET $path failed', name: 'syscredi.api', error: error);
      if (!error.uncertain) rethrow;
      final cached = await store.read(cacheKey);
      if (cached != null) return jsonDecode(cached);
      rethrow;
    }
  }

  @override
  Future<Uint8List> bytes(String path) => transport.requestBytes(path);

  String _cacheKey(String path) {
    final actor = userId() ?? 'anonymous';
    final safe = base64Url.encode(utf8.encode(path));
    return 'syscredi.v3.$scope.cache.$actor.$_cacheEpoch.$safe';
  }

  Future<void> _invalidate(String path) async {
    final actor = userId();
    if (actor == null) return;
    final resource = path.split('?').first;
    clearReadCache();
    await store.delete(_cacheKey(resource));
    // A mutation of /clients/:id (or any other item endpoint) also makes the
    // parent collection stale. Clear both keys so an/uncertain read
    // cannot resurrect the previous list.
    final parts = resource.split('/');
    if (parts.length > 2 && parts[1].isNotEmpty) {
      await store.delete(_cacheKey('/${parts[1]}'));
    }
  }

  @override
  Future<List<Json>> page(
    String path, {
    int offset = 0,
    int limit = 50,
  }) async => (await get('$path?limit=$limit&offset=$offset') as List)
      .map((r) => Map<String, dynamic>.from(r))
      .toList();
  @override
  Future<dynamic> write(String method, String path, Json body) async {
    if (_writing) throw const ApiFailure('Aguarde a operação em curso.');
    final actor = userId();
    if (actor == null) {
      throw const ApiFailure('Entre novamente.', status: 401);
    }
    _writing = true;
    try {
      var rows = await pending();
      if (rows.isNotEmpty) {
        try {
          final outcome = await get('/operations/${rows.first.key}') as Map;
          if ([
            'confirmed',
            'cancelled',
            'failed',
          ].contains(outcome['status'])) {
            await _save(actor, []);
            rows = [];
          }
        } on ApiFailure catch (error) {
          if (!error.uncertain && error.status != 401) {
            await _save(actor, []);
            rows = [];
          }
        }
      }
      // Do not allow a second intention to hide an uncertain first payment.
      if (rows.isNotEmpty) {
        throw const ApiFailure(
          'Existe uma operação por confirmar. Abra Pendências e consulte o resultado antes de criar outra.',
        );
      }
      final operation = PendingWrite(
        key: newKey(),
        userId: actor,
        method: method,
        path: path,
        body: jsonDecode(jsonEncode(body)) as Json,
      );
      await _save(actor, [
        operation,
      ]); // Persist before any request leaves this device.
      return await _send(operation);
    } finally {
      _writing = false;
    }
  }

  @override
  Future<dynamic> publicWrite(String method, String path, Json body) =>
      transport.requestPublic(method, path, body: body);

  @override
  Future<dynamic> retry(PendingWrite operation) async {
    if (_writing) throw const ApiFailure('Aguarde a operação em curso.');
    _writing = true;
    try {
      if (userId() != operation.userId) {
        throw const ApiFailure(
          'Esta operação pertence a outro utilizador.',
          status: 403,
        );
      }
      final persisted = await pending();
      if (!persisted.any(
        (p) =>
            p.key == operation.key &&
            jsonEncode(p.toJson()) == jsonEncode(operation.toJson()),
      )) {
        throw const ApiFailure(
          'Operação pendente não encontrada. Actualize a lista.',
        );
      }
      final outcome = await get('/operations/${operation.key}') as Map;
      if (outcome['status'] == 'confirmed' ||
          outcome['status'] == 'cancelled') {
        await _save(operation.userId, []);
        if (outcome['status'] == 'cancelled') {
          throw const ApiFailure(
            'A operação foi cancelada antes de ser executada.',
            status: 409,
          );
        }
        return outcome['result'];
      }
      return await _send(operation);
    } finally {
      _writing = false;
    }
  }

  @override
  Future<String> cancel(PendingWrite operation) async {
    if (_writing) throw const ApiFailure('Aguarde a operação em curso.');
    if (userId() != operation.userId) {
      throw const ApiFailure('Operação de outro utilizador.', status: 403);
    }
    _writing = true;
    try {
      final outcome =
          await transport.request(
                'POST',
                '/operations/${operation.key}/cancel',
                idempotencyKey: operation.key,
                expectedUser: operation.userId,
              )
              as Map;
      if (!['confirmed', 'cancelled'].contains(outcome['status'])) {
        throw const ApiFailure('Resultado desconhecido.');
      }
      await _save(operation.userId, []);
      return outcome['status'] as String;
    } finally {
      _writing = false;
    }
  }

  Future<dynamic> _send(PendingWrite operation) async {
    try {
      final result = await transport.request(
        operation.method,
        operation.path,
        body: operation.body,
        idempotencyKey: operation.key,
        expectedUser: operation.userId,
      );
      try {
        await _save(operation.userId, []);
        await _invalidate(operation.path);
      } catch (_) {
        // The server result is authoritative. A local cache/key-value cleanup
        // failure must not report a confirmed remote mutation as failed.
      }
      final resource = operation.path.split('?').first;
      final parts = resource.split('/');
      if (parts.length > 2 && parts[1].isNotEmpty) {}
      return result;
    } on ApiFailure catch (error) {
      // Keep a 401 intention because the identity may have changed while the
      // request was in flight. Other definitive failures were rejected before
      // execution and must not block every subsequent operation.
      if (!error.uncertain && error.status != 401) {
        await _save(operation.userId, []);
      }
      rethrow;
    }
  }

  @override
  void close() => transport.close();
}
