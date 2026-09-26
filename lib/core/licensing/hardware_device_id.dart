import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HardwareDeviceId {
  const HardwareDeviceId._();

  static const _preferenceKey = 'syscredi.device.id';

  static Future<String> resolve(SharedPreferences preferences) async {
    final raw = await _hardwareIdentity();
    if (raw != null && raw.trim().isNotEmpty) {
      final digest = sha256.convert(utf8.encode('syscredi|$raw')).toString();
      final value = _asUuid(digest).toUpperCase();
      await preferences.setString(_preferenceKey, value);
      return value;
    }
    final saved = preferences.getString(_preferenceKey);
    final value = saved ?? const Uuid().v4();
    if (saved == null) await preferences.setString(_preferenceKey, value);
    return value.toUpperCase();
  }

  static Future<String?> _hardwareIdentity() async {
    if (kIsWeb) return null;
    final plugin = DeviceInfoPlugin();
    try {
      return switch (defaultTargetPlatform) {
        TargetPlatform.macOS => (await plugin.macOsInfo).systemGUID,
        TargetPlatform.windows => (await plugin.windowsInfo).deviceId,
        TargetPlatform.linux => (await plugin.linuxInfo).machineId,
        TargetPlatform.android => (await plugin.androidInfo).id,
        TargetPlatform.iOS => (await plugin.iosInfo).identifierForVendor,
        TargetPlatform.fuchsia => null,
      };
    } catch (_) {
      return null;
    }
  }

  static String _asUuid(String hex) {
    final chars = hex.substring(0, 32).split('');
    chars[12] = '4';
    chars[16] = switch (int.parse(chars[16], radix: 16) & 3) {
      0 => '8',
      1 => '9',
      2 => 'a',
      _ => 'b',
    };
    final normalized = chars.join();
    return '${normalized.substring(0, 8)}-'
        '${normalized.substring(8, 12)}-'
        '${normalized.substring(12, 16)}-'
        '${normalized.substring(16, 20)}-'
        '${normalized.substring(20, 32)}';
  }
}
