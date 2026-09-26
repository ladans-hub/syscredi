import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/licensing/hardware_device_id.dart';
import '../domain/repository.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.active,
    required this.trial,
    required this.deviceId,
    required this.trialDaysLeft,
    this.plan,
    this.expiresAt,
    this.package,
    this.deviceLimit,
  });

  final bool active;
  final bool trial;
  final String deviceId;
  final int trialDaysLeft;
  final String? plan;
  final DateTime? expiresAt;
  final String? package;
  final int? deviceLimit;
}

class SubscriptionService {
  const SubscriptionService(this.repository);

  static const trialDaysTotal = 7;
  final Repository repository;

  Future<SubscriptionStatus> status({String? organizationId}) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await _deviceId(prefs);
    final now = DateTime.now().toUtc();
    final localPlan = prefs.getString('syscredi.license.plan');
    final localExpiry = DateTime.tryParse(
      prefs.getString('syscredi.license.expiresAt') ?? '',
    );
    final localOrganizationId = prefs.getString(
      'syscredi.license.organizationId',
    );
    final localPackage = prefs.getString('syscredi.license.package');
    final localDeviceLimit = prefs.getInt('syscredi.license.deviceLimit');
    if ((localPlan == null ||
            localExpiry == null ||
            !localExpiry.isAfter(now)) &&
        organizationId != null &&
        organizationId.isNotEmpty) {
      await _restoreOrganizationLicense(prefs, organizationId, now);
    }
    final restoredPlan = prefs.getString('syscredi.license.plan');
    final restoredExpiry = DateTime.tryParse(
      prefs.getString('syscredi.license.expiresAt') ?? '',
    );
    final restoredOrganizationId = prefs.getString(
      'syscredi.license.organizationId',
    );
    final restoredPackage = prefs.getString('syscredi.license.package');
    final restoredDeviceLimit = prefs.getInt('syscredi.license.deviceLimit');
    final organizationMatches =
        organizationId == null ||
        organizationId.isEmpty ||
        (restoredOrganizationId ?? localOrganizationId) == organizationId;
    final activePlan = restoredPlan ?? localPlan;
    final activeExpiry = restoredExpiry ?? localExpiry;
    final activePackage = restoredPackage ?? localPackage;
    final activeDeviceLimit = restoredDeviceLimit ?? localDeviceLimit;
    if (activePlan != null &&
        activeExpiry != null &&
        activeExpiry.isAfter(now) &&
        organizationMatches) {
      final deviceRegistration = await _registerDevice(
        organizationId: organizationId,
        deviceId: deviceId,
        package: activePackage,
        deviceLimit: activeDeviceLimit,
      );
      if (deviceRegistration == _DeviceRegistration.limitReached) {
        return SubscriptionStatus(
          active: false,
          trial: false,
          deviceId: deviceId,
          trialDaysLeft: 0,
          plan: activePlan,
          expiresAt: activeExpiry,
          package: activePackage,
          deviceLimit: activeDeviceLimit,
        );
      }
      return SubscriptionStatus(
        active: true,
        trial: false,
        deviceId: deviceId,
        trialDaysLeft: 0,
        plan: activePlan,
        expiresAt: activeExpiry,
        package: activePackage,
        deviceLimit: activeDeviceLimit,
      );
    }
    try {
      final remote = Map<String, dynamic>.from(
        await repository.get('/subscription/status') as Map,
      );
      final remoteExpiry = DateTime.tryParse('${remote['expires_at'] ?? ''}');
      if (remote['active'] == true) {
        return SubscriptionStatus(
          active: true,
          trial: false,
          deviceId: deviceId,
          trialDaysLeft: 0,
          plan: '${remote['plan'] ?? 'Activo'}',
          expiresAt: remoteExpiry,
        );
      }
    } catch (_) {
      // A licença local e o trial continuam disponíveis sem ligação.
    }
    final savedStart = DateTime.tryParse(
      prefs.getString('syscredi.trial.startedAt') ?? '',
    );
    final startedAt = savedStart ?? now;
    if (savedStart == null) {
      await prefs.setString(
        'syscredi.trial.startedAt',
        startedAt.toIso8601String(),
      );
    }
    final elapsedDays = now.difference(startedAt).inDays;
    final daysLeft = (trialDaysTotal - elapsedDays).clamp(0, trialDaysTotal);
    return SubscriptionStatus(
      active: daysLeft > 0,
      trial: true,
      deviceId: deviceId,
      trialDaysLeft: daysLeft,
    );
  }

  Future<String> deviceId() async =>
      _deviceId(await SharedPreferences.getInstance());

  Future<String> _deviceId(SharedPreferences prefs) async {
    return HardwareDeviceId.resolve(prefs);
  }

  Future<_DeviceRegistration> _registerDevice({
    required String? organizationId,
    required String deviceId,
    required String? package,
    required int? deviceLimit,
  }) async {
    if (organizationId == null || organizationId.isEmpty || package == null) {
      return _DeviceRegistration.unavailable;
    }
    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('syscredi_license_devices')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('device_id', deviceId.toLowerCase())
          .maybeSingle();
      if (existing != null) {
        await client
            .from('syscredi_license_devices')
            .update({
              'last_seen_at': DateTime.now().toUtc().toIso8601String(),
              'active': true,
            })
            .eq('id', existing['id']);
        return _DeviceRegistration.allowed;
      }
      if (package != 'premium') {
        final rows = await client
            .from('syscredi_license_devices')
            .select('id')
            .eq('organization_id', organizationId)
            .eq('active', true);
        if (rows.length >= (deviceLimit ?? 0)) {
          return _DeviceRegistration.limitReached;
        }
      }
      await client.from('syscredi_license_devices').insert({
        'organization_id': organizationId,
        'device_id': deviceId.toLowerCase(),
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
        'active': true,
      });
      return _DeviceRegistration.allowed;
    } catch (_) {
      return _DeviceRegistration.unavailable;
    }
  }

  Future<void> _restoreOrganizationLicense(
    SharedPreferences prefs,
    String organizationId,
    DateTime now,
  ) async {
    try {
      final row = await Supabase.instance.client
          .from('syscredi_licenses')
          .select('plan, expires_at, package, device_limit, activation_code')
          .eq('organization_id', organizationId)
          .eq('active', true)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return;
      final expiry = DateTime.tryParse('${row['expires_at'] ?? ''}');
      if (expiry == null || !expiry.isAfter(now)) return;
      await prefs.setString('syscredi.license.plan', '${row['plan']}');
      await prefs.setString(
        'syscredi.license.expiresAt',
        expiry.toIso8601String(),
      );
      await prefs.setString('syscredi.license.organizationId', organizationId);
      await prefs.setString('syscredi.license.package', '${row['package']}');
      final limit = row['device_limit'];
      if (limit == null) {
        await prefs.remove('syscredi.license.deviceLimit');
      } else {
        await prefs.setInt(
          'syscredi.license.deviceLimit',
          (limit as num).toInt(),
        );
      }
      await prefs.setString(
        'syscredi.license.code',
        '${row['activation_code']}',
      );
    } catch (_) {
      // A recuperação remota é best-effort; o trial continua disponível.
    }
  }
}

enum _DeviceRegistration { allowed, limitReached, unavailable }
