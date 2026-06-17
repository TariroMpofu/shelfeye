import '../services/licence_constants.dart';

/// Enforcement tiers. With strict per-device licensing only three occur:
/// active, expiringSoon (staff nudge), paused (device blocked → shopper "short
/// break"). `lapsedInGrace` is retained for compatibility but unused.
enum LicenceTier { active, expiringSoon, lapsedInGrace, paused }

/// Last-known-good device verdict from the gate. Persisted so an offline kiosk
/// keeps the correct tier across restarts (the gate's own cache is authoritative
/// for the 48h offline window; this mirrors it for the UI).
class Licence {
  /// Whether this device is currently entitled (seat held, store active,
  /// not expired). `false` → paused.
  final bool allowed;

  /// Verdict code: new_device, existing_device, reinstall_merged, offline_cached
  /// (allowed); device_limit_reached, entitlement_revoked, licence_expired,
  /// store_inactive, device_inactive, emulator_blocked, store_not_found,
  /// offline_grace_expired, offline_no_cache (blocked).
  final String reason;

  /// Subscription expiry (null = no time limit).
  final DateTime? validUntil;
  final DateTime? lastVerifiedAt;
  final String storeId;

  const Licence({
    this.allowed = true,
    this.reason = '',
    this.validUntil,
    this.lastVerifiedAt,
    this.storeId = '',
  });

  LicenceTier tierAt(DateTime now) {
    if (!allowed) return LicenceTier.paused;
    final exp = validUntil;
    if (exp == null) return LicenceTier.active;
    if (now.isAfter(exp)) return LicenceTier.paused; // strict: no shopper grace
    if (now.isAfter(exp.subtract(LicenceConstants.warnWindow))) {
      return LicenceTier.expiringSoon;
    }
    return LicenceTier.active;
  }

  int daysToExpiry(DateTime now) => validUntil == null
      ? 9999
      : validUntil!.difference(DateTime(now.year, now.month, now.day)).inDays;

  /// Whether the verdict came from the offline cache (server not reached).
  bool get fromCache => reason == 'offline_cached';

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        'reason': reason,
        'valid_until': validUntil?.toIso8601String(),
        'last_verified_at': lastVerifiedAt?.toIso8601String(),
        'store_id': storeId,
      };

  factory Licence.fromJson(Map<String, dynamic> j) => Licence(
        allowed: j['allowed'] == true,
        reason: (j['reason'] ?? '').toString(),
        validUntil: _date(j['valid_until']),
        lastVerifiedAt: _date(j['last_verified_at']),
        storeId: (j['store_id'] ?? '').toString(),
      );

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s.length == 10 ? '${s}T00:00:00' : s);
  }
}
