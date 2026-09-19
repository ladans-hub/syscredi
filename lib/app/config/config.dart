import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const dataLayerEnabled = bool.fromEnvironment(
    'DATA_LAYER_ENABLED',
    defaultValue: false,
  );

  const AppConfig({
    required this.apiUrl,
    required this.supabaseUrl,
    required this.publishableKey,
  });
  static const environment = AppConfig(
    apiUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://syscredi-backend.vercel.app/v1',
    ),
    supabaseUrl: String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://fpfaczcwlozbguphhoff.supabase.co',
    ),
    publishableKey: String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_bC-1ZfDLYrGdpIQ70BZcGQ_nOsXYcRZ',
    ),
  );
  final String apiUrl, supabaseUrl, publishableKey;
  String get scope =>
      sha256.convert(utf8.encode('$apiUrl|$supabaseUrl')).toString();
  String? validate({bool release = kReleaseMode}) {
    for (final entry in {
      'API_BASE_URL': apiUrl,
      'SUPABASE_URL': supabaseUrl,
    }.entries) {
      final uri = Uri.tryParse(entry.value);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (uri.scheme != 'https' &&
              !(uri.scheme == 'http' &&
                  !release &&
                  ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host)))) {
        return 'Configure ${entry.key} com uma URL HTTPS válida.';
      }
    }
    if (!apiUrl.endsWith('/v1')) return 'API_BASE_URL deve terminar em /v1.';
    if (!publishableKey.startsWith('sb_publishable_') &&
        !publishableKey.startsWith('eyJ')) {
      return 'Configure a chave pública do Supabase.';
    }
    // Legacy JWT keys are accepted only with the anon role.
    if (publishableKey.startsWith('eyJ')) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(publishableKey.split('.')[1])),
          ),
        );
        if (payload['role'] != 'anon') {
          return 'Use apenas a chave pública (anon), nunca service_role.';
        }
      } catch (_) {
        return 'Chave pública inválida.';
      }
    }
    return null;
  }
}
