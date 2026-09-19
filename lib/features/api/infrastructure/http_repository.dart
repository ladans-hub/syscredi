import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../domain/repository.dart';
import '../application/reliable_repository.dart';

class ApiClient extends ReliableRepository {
  ApiClient({
    required String baseUrl,
    required super.scope,
    required super.store,
    required super.userId,
    required Future<String?> Function() accessToken,
    required Future<void> Function() refreshToken,
    http.Client? client,
    Duration timeout = const Duration(seconds: 25),
  }) : super(
         newKey: const Uuid().v4,
         transport: HttpTransport(
           baseUrl: baseUrl,
           userId: userId,
           accessToken: accessToken,
           refreshToken: refreshToken,
           client: client,
           timeout: timeout,
         ),
       );
}

class HttpTransport implements Transport {
  HttpTransport({
    required this.baseUrl,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 25),
  }) : _client = client ?? http.Client();
  final String baseUrl;
  final String? Function() userId;
  final Future<String?> Function() accessToken;
  final Future<void> Function() refreshToken;
  final Duration timeout;
  final http.Client _client;
  void _validatePath(String path) {
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        path.contains('://') ||
        path.contains('..')) {
      throw ArgumentError('Caminho inválido.');
    }
  }

  @override
  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    String? idempotencyKey,
    String? expectedUser,
    bool refreshed = false,
    int transientAttempt = 0,
  }) async {
    _validatePath(path);
    final normalizedMethod = method.toUpperCase();
    if (normalizedMethod != 'GET' &&
        normalizedMethod != 'HEAD' &&
        (idempotencyKey == null || idempotencyKey.trim().isEmpty)) {
      throw const ApiFailure(
        'A operação precisa de uma chave de idempotência persistida.',
      );
    }
    final actor = expectedUser ?? userId();
    if (actor == null || userId() != actor) {
      throw const ApiFailure('Entre novamente.', status: 401);
    }
    final token = await accessToken();
    if (token == null || userId() != actor) {
      throw const ApiFailure('Entre novamente.', status: 401);
    }
    try {
      final outgoing = http.Request(method, Uri.parse('$baseUrl$path'))
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Idempotency-Key': ?idempotencyKey,
        });
      if (body != null) outgoing.body = jsonEncode(body);
      final response = await _client
          .send(outgoing)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (userId() != actor) {
        throw const ApiFailure(
          'A sessão mudou. Entre com o utilizador original para consultar a operação.',
          status: 401,
        );
      }
      if (response.statusCode == 401 && !refreshed) {
        await refreshToken();
        return request(
          method,
          path,
          body: body,
          idempotencyKey: idempotencyKey,
          expectedUser: actor,
          refreshed: true,
        );
      }
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
      // Mutations carry an idempotency key, so they can be retried safely after
      // a transient response. Reads are retried by the sync/recovery layer,
      // which avoids multiplying concurrent catalogue requests here.
      if (idempotencyKey != null &&
          [408, 425, 429, 500, 502, 503, 504].contains(response.statusCode) &&
          transientAttempt < 2) {
        final wait = Duration(milliseconds: 150 * (1 << transientAttempt));
        await Future<void>.delayed(wait);
        return request(
          method,
          path,
          body: body,
          idempotencyKey: idempotencyKey,
          expectedUser: actor,
          refreshed: refreshed,
          transientAttempt: transientAttempt + 1,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map ? data['message'] : null;
        throw ApiFailure(
          message is List
              ? message.join('\n')
              : message is String
              ? message
              : 'Não foi possível concluir o pedido (${response.statusCode}).',
          status: response.statusCode,
        );
      }
      if (data == null) {
        throw const ApiFailure(
          'Resposta inválida. Consulte as pendências antes de repetir.',
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiFailure(
        'Sem resposta do servidor. A operação não está confirmada; consulte Pendências.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        'Servidor indisponível. A operação não foi alterada.',
      );
    }
  }

  @override
  Future<dynamic> requestPublic(
    String method,
    String path, {
    Json? body,
  }) async {
    _validatePath(path);
    try {
      final outgoing = http.Request(method, Uri.parse('$baseUrl$path'))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json';
      if (body != null) outgoing.body = jsonEncode(body);
      final response = await _client
          .send(outgoing)
          .then(http.Response.fromStream)
          .timeout(timeout);
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map && data['message'] is String
            ? data['message'] as String
            : 'Não foi possível criar o acesso (${response.statusCode}).';
        throw ApiFailure(message, status: response.statusCode);
      }
      if (data is! Map)
        throw const ApiFailure('Resposta inválida do onboarding.');
      return data;
    } on TimeoutException {
      throw const ApiFailure('Sem resposta do servidor.');
    } on http.ClientException {
      throw const ApiFailure('Servidor indisponível.');
    }
  }

  @override
  Future<Uint8List> requestBytes(String path, {String? expectedUser}) async {
    return _requestBytes(path, expectedUser: expectedUser);
  }

  Future<Uint8List> _requestBytes(
    String path, {
    String? expectedUser,
    bool refreshed = false,
  }) async {
    _validatePath(path);
    final actor = expectedUser ?? userId();
    if (actor == null || userId() != actor)
      throw const ApiFailure('Entre novamente.', status: 401);
    final token = await accessToken();
    if (token == null || userId() != actor)
      throw const ApiFailure('Entre novamente.', status: 401);
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(timeout);
      if (response.statusCode == 401 && !refreshed) {
        await refreshToken();
        return _requestBytes(path, expectedUser: actor, refreshed: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure(
          'Não foi possível gerar o documento (${response.statusCode}).',
          status: response.statusCode,
        );
      }
      return Uint8List.fromList(response.bodyBytes);
    } on TimeoutException {
      throw const ApiFailure('Sem resposta do servidor.');
    } on http.ClientException {
      throw const ApiFailure('Servidor indisponível.');
    }
  }

  @override
  void close() => _client.close();
}
