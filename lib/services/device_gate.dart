import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'licence_constants.dart';

/// Outcome of a device-gate validation. [reason] is the server/cache verdict
/// code (e.g. device_limit_reached, entitlement_revoked, licence_expired,
/// new_device, existing_device, offline_cached, offline_grace_expired).
class GateResult {
  final bool allowed;
  final String? reason;
  final DateTime? validUntil;
  const GateResult({required this.allowed, this.reason, this.validUntil});
}

class _DeviceData {
  final String hardwareId; // "platform:system_id"
  final String deviceName;
  final String deviceModel;
  final String systemName;
  final String systemVersion;
  final bool isPhysical;
  final String? deviceFingerprint;
  final String installToken;
  const _DeviceData({
    required this.hardwareId,
    required this.deviceName,
    required this.deviceModel,
    required this.systemName,
    required this.systemVersion,
    required this.isPhysical,
    required this.installToken,
    this.deviceFingerprint,
  });
}

/// Darwin hardware id → Apple marketing name (so "iPhone14,4" reads as
/// "iPhone 13 mini" in the device record). Unknown ids fall through to the raw
/// identifier (so newer hardware is still recorded, just un-prettified).
const _iosModelNames = <String, String>{
  // ── iPhone ──────────────────────────────────────────────────────────────
  'iPhone1,1': 'iPhone',
  'iPhone1,2': 'iPhone 3G',
  'iPhone2,1': 'iPhone 3GS',
  'iPhone3,1': 'iPhone 4',
  'iPhone3,2': 'iPhone 4',
  'iPhone3,3': 'iPhone 4',
  'iPhone4,1': 'iPhone 4S',
  'iPhone5,1': 'iPhone 5',
  'iPhone5,2': 'iPhone 5',
  'iPhone5,3': 'iPhone 5c',
  'iPhone5,4': 'iPhone 5c',
  'iPhone6,1': 'iPhone 5s',
  'iPhone6,2': 'iPhone 5s',
  'iPhone7,1': 'iPhone 6 Plus',
  'iPhone7,2': 'iPhone 6',
  'iPhone8,1': 'iPhone 6s',
  'iPhone8,2': 'iPhone 6s Plus',
  'iPhone8,4': 'iPhone SE (1st gen)',
  'iPhone9,1': 'iPhone 7',
  'iPhone9,2': 'iPhone 7 Plus',
  'iPhone9,3': 'iPhone 7',
  'iPhone9,4': 'iPhone 7 Plus',
  'iPhone10,1': 'iPhone 8',
  'iPhone10,2': 'iPhone 8 Plus',
  'iPhone10,3': 'iPhone X',
  'iPhone10,4': 'iPhone 8',
  'iPhone10,5': 'iPhone 8 Plus',
  'iPhone10,6': 'iPhone X',
  'iPhone11,2': 'iPhone XS',
  'iPhone11,4': 'iPhone XS Max',
  'iPhone11,6': 'iPhone XS Max',
  'iPhone11,8': 'iPhone XR',
  'iPhone12,1': 'iPhone 11',
  'iPhone12,3': 'iPhone 11 Pro',
  'iPhone12,5': 'iPhone 11 Pro Max',
  'iPhone12,8': 'iPhone SE (2nd gen)',
  'iPhone13,1': 'iPhone 12 mini',
  'iPhone13,2': 'iPhone 12',
  'iPhone13,3': 'iPhone 12 Pro',
  'iPhone13,4': 'iPhone 12 Pro Max',
  'iPhone14,2': 'iPhone 13 Pro',
  'iPhone14,3': 'iPhone 13 Pro Max',
  'iPhone14,4': 'iPhone 13 mini',
  'iPhone14,5': 'iPhone 13',
  'iPhone14,6': 'iPhone SE (3rd gen)',
  'iPhone14,7': 'iPhone 14',
  'iPhone14,8': 'iPhone 14 Plus',
  'iPhone15,2': 'iPhone 14 Pro',
  'iPhone15,3': 'iPhone 14 Pro Max',
  'iPhone15,4': 'iPhone 15',
  'iPhone15,5': 'iPhone 15 Plus',
  'iPhone16,1': 'iPhone 15 Pro',
  'iPhone16,2': 'iPhone 15 Pro Max',
  'iPhone17,1': 'iPhone 16 Pro',
  'iPhone17,2': 'iPhone 16 Pro Max',
  'iPhone17,3': 'iPhone 16',
  'iPhone17,4': 'iPhone 16 Plus',
  'iPhone17,5': 'iPhone 16e',
  // ── iPad ────────────────────────────────────────────────────────────────
  'iPad1,1': 'iPad',
  'iPad2,1': 'iPad 2',
  'iPad2,2': 'iPad 2',
  'iPad2,3': 'iPad 2',
  'iPad2,4': 'iPad 2',
  'iPad3,1': 'iPad (3rd gen)',
  'iPad3,2': 'iPad (3rd gen)',
  'iPad3,3': 'iPad (3rd gen)',
  'iPad3,4': 'iPad (4th gen)',
  'iPad3,5': 'iPad (4th gen)',
  'iPad3,6': 'iPad (4th gen)',
  'iPad6,11': 'iPad (5th gen)',
  'iPad6,12': 'iPad (5th gen)',
  'iPad7,5': 'iPad (6th gen)',
  'iPad7,6': 'iPad (6th gen)',
  'iPad7,11': 'iPad (7th gen)',
  'iPad7,12': 'iPad (7th gen)',
  'iPad11,6': 'iPad (8th gen)',
  'iPad11,7': 'iPad (8th gen)',
  'iPad12,1': 'iPad (9th gen)',
  'iPad12,2': 'iPad (9th gen)',
  'iPad13,18': 'iPad (10th gen)',
  'iPad13,19': 'iPad (10th gen)',
  'iPad15,7': 'iPad (A16) (11th gen)',
  // ── iPad mini ──────────────────────────────────────────────────────────
  'iPad2,5': 'iPad mini',
  'iPad2,6': 'iPad mini',
  'iPad2,7': 'iPad mini',
  'iPad4,4': 'iPad mini 2',
  'iPad4,5': 'iPad mini 2',
  'iPad4,6': 'iPad mini 2',
  'iPad4,7': 'iPad mini 3',
  'iPad4,8': 'iPad mini 3',
  'iPad4,9': 'iPad mini 3',
  'iPad5,1': 'iPad mini 4',
  'iPad5,2': 'iPad mini 4',
  'iPad11,1': 'iPad mini (5th gen)',
  'iPad11,2': 'iPad mini (5th gen)',
  'iPad14,1': 'iPad mini (6th gen)',
  'iPad14,2': 'iPad mini (6th gen)',
  'iPad16,1': 'iPad mini (A17 Pro / 7th gen)',
  'iPad16,2': 'iPad mini (A17 Pro / 7th gen)',
  // ── iPad Air ───────────────────────────────────────────────────────────
  'iPad4,1': 'iPad Air',
  'iPad4,2': 'iPad Air',
  'iPad4,3': 'iPad Air',
  'iPad5,3': 'iPad Air 2',
  'iPad5,4': 'iPad Air 2',
  'iPad11,3': 'iPad Air (3rd gen)',
  'iPad11,4': 'iPad Air (3rd gen)',
  'iPad13,1': 'iPad Air (4th gen)',
  'iPad13,2': 'iPad Air (4th gen)',
  'iPad13,16': 'iPad Air (5th gen)',
  'iPad13,17': 'iPad Air (5th gen)',
  'iPad14,8': 'iPad Air 11" (M2)',
  'iPad14,9': 'iPad Air 11" (M2)',
  'iPad14,10': 'iPad Air 13" (M2)',
  'iPad14,11': 'iPad Air 13" (M2)',
  // ── iPad Pro ───────────────────────────────────────────────────────────
  'iPad6,3': 'iPad Pro (9.7-inch)',
  'iPad6,4': 'iPad Pro (9.7-inch)',
  'iPad6,7': 'iPad Pro (12.9-inch) (1st gen)',
  'iPad6,8': 'iPad Pro (12.9-inch) (1st gen)',
  'iPad7,1': 'iPad Pro (12.9-inch) (2nd gen)',
  'iPad7,2': 'iPad Pro (12.9-inch) (2nd gen)',
  'iPad7,3': 'iPad Pro (10.5-inch)',
  'iPad7,4': 'iPad Pro (10.5-inch)',
  'iPad8,1': 'iPad Pro 11" (1st gen)',
  'iPad8,2': 'iPad Pro 11" (1st gen)',
  'iPad8,3': 'iPad Pro 11" (1st gen)',
  'iPad8,4': 'iPad Pro 11" (1st gen)',
  'iPad8,5': 'iPad Pro 12.9" (3rd gen)',
  'iPad8,6': 'iPad Pro 12.9" (3rd gen)',
  'iPad8,7': 'iPad Pro 12.9" (3rd gen)',
  'iPad8,8': 'iPad Pro 12.9" (3rd gen)',
  'iPad8,9': 'iPad Pro 11" (2nd gen)',
  'iPad8,10': 'iPad Pro 11" (2nd gen)',
  'iPad8,11': 'iPad Pro 12.9" (4th gen)',
  'iPad8,12': 'iPad Pro 12.9" (4th gen)',
  'iPad13,4': 'iPad Pro 11" (3rd gen)',
  'iPad13,5': 'iPad Pro 11" (3rd gen)',
  'iPad13,6': 'iPad Pro 11" (3rd gen)',
  'iPad13,7': 'iPad Pro 11" (3rd gen)',
  'iPad13,8': 'iPad Pro 12.9" (5th gen)',
  'iPad13,9': 'iPad Pro 12.9" (5th gen)',
  'iPad13,10': 'iPad Pro 12.9" (5th gen)',
  'iPad13,11': 'iPad Pro 12.9" (5th gen)',
  'iPad14,3': 'iPad Pro 11" (M2 / 4th gen)',
  'iPad14,4': 'iPad Pro 11" (M2 / 4th gen)',
  'iPad14,5': 'iPad Pro 12.9" (M2 / 6th gen)',
  'iPad14,6': 'iPad Pro 12.9" (M2 / 6th gen)',
  'iPad16,3': 'iPad Pro 11" (M4)',
  'iPad16,4': 'iPad Pro 11" (M4)',
  'iPad16,5': 'iPad Pro 13" (M4)',
  'iPad16,6': 'iPad Pro 13" (M4)',
  // ── iPod touch ─────────────────────────────────────────────────────────
  'iPod1,1': 'iPod touch',
  'iPod2,1': 'iPod touch (2nd gen)',
  'iPod3,1': 'iPod touch (3rd gen)',
  'iPod4,1': 'iPod touch (4th gen)',
  'iPod5,1': 'iPod touch (5th gen)',
  'iPod7,1': 'iPod touch (6th gen)',
  'iPod9,1': 'iPod touch (7th gen)',
  // ── Simulators ─────────────────────────────────────────────────────────
  'i386': 'Simulator',
  'x86_64': 'Simulator',
  'arm64': 'Simulator',
};

/// Strict per-device licence gate (ported from StockRoom). Registers + seat-
/// counts this device against the store, verifies an HMAC-signed verdict, and
/// caches an approval for [LicenceConstants.offlineGrace] so a device can ride
/// out connectivity gaps — but no longer.
class DeviceGate {
  // New value every launch (never persisted) so the server can detect reinstalls
  // even when the hardware id is stable (iOS Keychain UUID carried over).
  static final String _sessionInstallToken = const Uuid().v4();

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _kGateCache = 'gate_cache_v1';
  static const String _kGateCacheFallback = 'gate_cache_v1_fallback';
  static const String _kHardwareId = 'device_hardware_id_v1';

  /// A short device label for the staff screen (last 4 of the hardware id).
  static Future<String> fragment() async {
    try {
      final d = await _collect();
      final raw = d.hardwareId
          .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
          .toUpperCase();
      if (raw.isEmpty) return 'XXXX';
      return raw.length >= 4 ? raw.substring(raw.length - 4) : raw;
    } catch (_) {
      return 'XXXX';
    }
  }

  /// The current device's model (for the staff screen).
  static Future<String> deviceModel() async {
    try {
      return (await _collect()).deviceModel;
    } catch (_) {
      return 'device';
    }
  }

  /// Validate this device against Supabase. Falls back to the offline cache.
  static Future<GateResult> validate(String storeId, String storeName) async {
    _DeviceData? device;
    try {
      device = await _collect();
      final uri = Uri.parse(
        '${LicenceConstants.supabaseUrl}/rest/v1/rpc/validate_and_register_device',
      );
      final payload = <String, dynamic>{
        'store_id': storeId,
        'hardware_id': device.hardwareId,
        'device_name': device.deviceName,
        'device_model': device.deviceModel,
        'system_name': device.systemName,
        'system_version': device.systemVersion,
        'is_physical': device.isPhysical,
        'device_fingerprint': device.deviceFingerprint,
        'install_token': device.installToken,
        if (storeName.isNotEmpty) 'store_description': storeName,
      };

      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'apikey': LicenceConstants.supabaseAnonKey,
              'Authorization': 'Bearer ${LicenceConstants.supabaseAnonKey}',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final allowed = body['allowed'] == true;
        final reason = body['reason'] as String?;
        final validUntilStr = body['valid_until'] as String?;
        final serverHmac = body['hmac'] as String?;

        if (serverHmac != null) {
          final expected = _hmac(
            allowed,
            reason ?? '',
            validUntilStr ?? '',
            device.hardwareId,
            storeId,
          );
          if (serverHmac != expected) {
            debugPrint('DeviceGate: HMAC mismatch — using cache');
            return _offlineCache(storeId, device.hardwareId);
          }
        }

        if (allowed) {
          await _cache(
            storeId,
            device.hardwareId,
            reason ?? '',
            validUntilStr ?? '',
            serverHmac,
          );
        } else {
          await _clearCache(); // explicit block — no stale grace
        }
        return GateResult(
          allowed: allowed,
          reason: reason,
          validUntil: validUntilStr != null
              ? DateTime.tryParse(validUntilStr)
              : null,
        );
      }
      debugPrint('DeviceGate: HTTP ${res.statusCode} — trying cache');
    } catch (e) {
      debugPrint('DeviceGate: server unreachable — $e');
    }
    return _offlineCache(storeId, device?.hardwareId ?? '');
  }

  // ── offline cache ──────────────────────────────────────────────────────────
  static Future<GateResult> _offlineCache(
    String storeId,
    String hardwareId,
  ) async {
    String? raw;
    try {
      raw = await _secure.read(key: _kGateCache);
    } catch (_) {}
    if (raw == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        raw = prefs.getString(_kGateCacheFallback);
      } catch (_) {}
    }
    if (raw == null) {
      return const GateResult(allowed: false, reason: 'offline_no_cache');
    }
    try {
      final c = jsonDecode(raw) as Map<String, dynamic>;
      if ((c['store_id'] as String?) != storeId) {
        return const GateResult(allowed: false, reason: 'offline_no_cache');
      }
      final cachedAt = DateTime.tryParse((c['cached_at'] ?? '').toString());
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > LicenceConstants.offlineGrace) {
        await _clearCache();
        return const GateResult(
          allowed: false,
          reason: 'offline_grace_expired',
        );
      }
      final validUntilStr = c['valid_until'] as String?;
      if (validUntilStr != null && validUntilStr.isNotEmpty) {
        final vu = _parseValidUntil(validUntilStr);
        if (vu != null && DateTime.now().isAfter(vu)) {
          await _clearCache();
          return GateResult(
            allowed: false,
            reason: 'licence_expired',
            validUntil: vu,
          );
        }
      }
      final cachedHmac = c['hmac'] as String?;
      if (cachedHmac != null) {
        final hw = (c['hardware_id'] ?? hardwareId).toString();
        final expected = _hmac(
          true,
          (c['reason'] ?? '').toString(),
          validUntilStr ?? '',
          hw,
          storeId,
        );
        if (cachedHmac != expected) {
          await _clearCache();
          return const GateResult(allowed: false, reason: 'offline_no_cache');
        }
      }
      return GateResult(
        allowed: true,
        reason: 'offline_cached',
        validUntil: validUntilStr != null
            ? DateTime.tryParse(validUntilStr)
            : null,
      );
    } catch (_) {
      return const GateResult(allowed: false, reason: 'offline_no_cache');
    }
  }

  static Future<void> _cache(
    String storeId,
    String hardwareId,
    String reason,
    String validUntilStr,
    String? hmac,
  ) async {
    final entry = jsonEncode({
      'store_id': storeId,
      'hardware_id': hardwareId,
      'reason': reason,
      'valid_until': validUntilStr,
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'hmac': ?hmac,
    });
    try {
      await _secure.write(key: _kGateCache, value: entry);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kGateCacheFallback, entry);
    } catch (_) {}
  }

  static Future<void> _clearCache() async {
    try {
      await _secure.delete(key: _kGateCache);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGateCacheFallback);
    } catch (_) {}
  }

  static DateTime? _parseValidUntil(String? s) {
    if (s == null || s.isEmpty) return null;
    final dt = DateTime.tryParse(s);
    if (dt == null) return null;
    if (!s.contains('T') && !s.contains(' ')) {
      return DateTime(dt.year, dt.month, dt.day + 1); // date-only = end of day
    }
    return dt;
  }

  static String _hmac(
    bool allowed,
    String reason,
    String validUntil,
    String hardwareId,
    String storeId,
  ) {
    final msg =
        '${allowed ? 'true' : 'false'}|$reason|$validUntil|$hardwareId|$storeId';
    return Hmac(
      sha256,
      utf8.encode(LicenceConstants.hmacSecret),
    ).convert(utf8.encode(msg)).toString();
  }

  // ── device identity ─────────────────────────────────────────────────────────
  static Future<_DeviceData> _collect() async {
    final plugin = DeviceInfoPlugin();
    final token = _sessionInstallToken;

    if (!kIsWeb && Platform.isAndroid) {
      final info = await plugin.androidInfo;
      // ANDROID_ID (info.id): scoped to the app signing key, survives reinstalls
      // and data clears, changes only on factory reset.
      return _DeviceData(
        hardwareId: 'android:${info.id}',
        deviceName: '${info.brand} ${info.model}',
        deviceModel: info.model,
        systemName: 'Android',
        systemVersion: info.version.release,
        isPhysical: info.isPhysicalDevice,
        deviceFingerprint: _fingerprint(
          'Android',
          info.manufacturer,
          info.model,
          info.version.release,
          info.isPhysicalDevice,
        ),
        installToken: token,
      );
    }

    if (!kIsWeb && Platform.isIOS) {
      final info = await plugin.iosInfo;
      // Keychain UUID survives app reinstall (not tied to the app sandbox); lost
      // only on factory reset. identifierForVendor is NOT used (resets on vendor
      // app removal).
      final systemId = await _stableId();
      final machine = info.utsname.machine;
      final model = info.isPhysicalDevice
          ? (_iosModelNames[machine] ?? machine)
          : 'Simulator/${info.model}';
      return _DeviceData(
        hardwareId: 'ios:$systemId',
        deviceName: info.name,
        deviceModel: model,
        systemName: info.systemName,
        systemVersion: info.systemVersion,
        isPhysical: info.isPhysicalDevice,
        deviceFingerprint: _fingerprint(
          'iOS',
          'Apple',
          machine,
          info.systemVersion,
          info.isPhysicalDevice,
        ),
        installToken: token,
      );
    }

    final id = await _stableId();
    return _DeviceData(
      hardwareId: '${kIsWeb ? 'web' : Platform.operatingSystem}:$id',
      deviceName: kIsWeb ? 'Web Browser' : Platform.operatingSystem,
      deviceModel: kIsWeb ? 'Browser' : Platform.operatingSystem,
      systemName: kIsWeb ? 'Web' : Platform.operatingSystem,
      systemVersion: kIsWeb ? '' : Platform.operatingSystemVersion,
      isPhysical: !kIsWeb,
      installToken: token,
    );
  }

  static String _fingerprint(
    String platform,
    String manufacturer,
    String model,
    String osVersion,
    bool isPhysical,
  ) {
    return [
      platform.trim(),
      manufacturer.trim().toLowerCase(),
      model.trim(),
      osVersion.trim(),
      isPhysical ? 'physical' : 'virtual',
    ].join('|');
  }

  /// A UUID generated once and persisted: iOS Keychain / Android Keystore so it
  /// survives reinstalls; SharedPreferences elsewhere.
  static Future<String> _stableId() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      String? id;
      try {
        id = await _secure.read(key: _kHardwareId);
      } catch (e) {
        debugPrint('DeviceGate: secure read failed — $e');
      }
      if (id == null) {
        id = const Uuid().v4();
        try {
          await _secure.write(key: _kHardwareId, value: id);
        } catch (e) {
          debugPrint('DeviceGate: CRITICAL secure write failed — $e');
        }
      }
      return id;
    }
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kHardwareId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_kHardwareId, id);
    }
    return id;
  }
}
