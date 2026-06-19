import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/licence.dart';
import 'device_gate.dart';
import 'licence_constants.dart';

/// Strict per-device licence state (mirrors StockRoom). Validates this device
/// against Supabase via [DeviceGate], seat-counted per store. Exposes the tier
/// so the shopper "short break" screen and the staff Licence section react.
///
/// Blocking is real and per-device: device_limit_reached, entitlement_revoked,
/// licence_expired, store_inactive, etc. all → [LicenceTier.paused]. Only a
/// connectivity gap within the 48h offline window keeps a previously-approved
/// device running.
class LicenceService extends ChangeNotifier {
  static const _kLicence = 'shelfline_licence_v1';

  Licence _licence = const Licence();
  bool _serverReachable = true;
  String _deviceLabel = '';
  String _deviceModel = '';
  Timer? _timer;
  bool _checking = false;

  Licence get licence => _licence;
  bool get serverReachable => _serverReachable;
  String get deviceLabel => _deviceLabel;
  String get deviceModel => _deviceModel;

  /// Dormant until Supabase is configured (then the app behaves as before).
  bool get enabled => LicenceConstants.configured;

  LicenceTier get tier =>
      enabled ? _licence.tierAt(DateTime.now()) : LicenceTier.active;
  bool get isPaused => tier == LicenceTier.paused;

  Future<void> start(String storeId, String storeName) async {
    if (!enabled || storeId.isEmpty) return;
    await _loadPersisted();
    DeviceGate.fragment().then((f) {
      _deviceLabel = f;
      notifyListeners();
    });
    DeviceGate.deviceModel().then((m) {
      _deviceModel = m;
      notifyListeners();
    });
    unawaited(refresh(storeId, storeName));
    _timer?.cancel();
    _timer = Timer.periodic(
        LicenceConstants.refreshInterval, (_) => refresh(storeId, storeName));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// One validation. Updates the verdict; persists last-known-good.
  Future<void> refresh(String storeId, String storeName) async {
    if (!enabled || _checking || storeId.isEmpty) return;
    _checking = true;
    try {
      final r = await DeviceGate.validate(storeId, storeName);
      // The gate already consulted its own cache on failure; we treat an
      // offline_* reason as "server not reached" for the staff status row.
      _serverReachable =
          r.reason != 'offline_cached' && !(r.reason ?? '').startsWith('offline');
      _licence = Licence(
        allowed: r.allowed,
        reason: r.reason ?? '',
        validUntil: r.validUntil,
        lastVerifiedAt: DateTime.now(),
        storeId: storeId,
      );
      debugPrint(
        'LicenceService: store=$storeId allowed=${r.allowed} '
        'reason=${r.reason} validUntil=${r.validUntil} '
        'serverReachable=$_serverReachable → tier=$tier',
      );
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('licence refresh failed: $e');
      _serverReachable = false;
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kLicence);
      if (raw != null && raw.isNotEmpty) {
        _licence = Licence.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLicence, jsonEncode(_licence.toJson()));
    } catch (_) {}
  }
}
