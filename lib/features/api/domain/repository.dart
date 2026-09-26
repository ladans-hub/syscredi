import 'dart:typed_data';

typedef Json = Map<String, dynamic>;

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status = 0});
  final String message;
  final int status;
  bool get uncertain =>
      status == 0 || status >= 500 || status == 408 || status == 429;
  @override
  String toString() => message;
}

class PendingWrite {
  const PendingWrite({
    required this.key,
    required this.userId,
    required this.method,
    required this.path,
    required this.body,
  });
  final String key, userId, method, path;
  final Json body;
  Json toJson() => {
    'key': key,
    'userId': userId,
    'method': method,
    'path': path,
    'body': body,
  };
  factory PendingWrite.fromJson(Json json) => PendingWrite(
    key: json['key'],
    userId: json['userId'],
    method: json['method'],
    path: json['path'],
    body: Map<String, dynamic>.from(json['body']),
  );
}

/// Port for the versioned central API; no dependency on an HTTP client or SDK.
abstract interface class Repository {
  Future<dynamic> get(String path);
  Future<Uint8List> bytes(String path);
  Future<List<Json>> page(String path, {int offset = 0, int limit = 50});
  Future<dynamic> write(String method, String path, Json body);
  Future<dynamic> publicWrite(String method, String path, Json body);
  Future<List<PendingWrite>> pending();
  Future<dynamic> retry(PendingWrite operation);
  Future<String> cancel(PendingWrite operation);
  void close();
}

abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

abstract interface class Transport {
  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    String? idempotencyKey,
    String? expectedUser,
  });
  Future<dynamic> requestPublic(String method, String path, {Json? body});
  Future<Uint8List> requestBytes(String path, {String? expectedUser});
  void close();
}

abstract interface class AuthGateway {
  String? get userId;
  bool get hasSession;
  Stream<bool> get sessionChanges;
  Stream<bool> get passwordRecoveryChanges;
  Future<String?> accessToken();
  Future<void> refreshToken();
  Future<void> login(String email, String password);
  Future<void> recoverPassword(String email);
  Future<void> updatePassword(String password);
  Future<void> register(String name, String email, String password);
  Future<void> adoptSession(String refreshToken);
  Future<void> logout();
}
