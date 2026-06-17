/// Strict per-device licence configuration (mirrors StockRoom). The device
/// registers against Supabase and is seat-counted per store (`max_devices`);
/// verdicts are HMAC-signed. Fill in the project URL + anon key after running
/// `supabase/device_licence_setup.sql`.
///
/// The anon key is safe to embed — Row-Level Security denies all direct table
/// access; the only thing it can do is call `validate_and_register_device`.
class LicenceConstants {
  static const String supabaseUrl = 'https://wxdwzvvzzfmfvxliqnpx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind4ZHd6dnZ6emZtZnZ4bGlxbnB4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2MDMwNjAsImV4cCI6MjA5NzE3OTA2MH0.0gTs742L1IYqow20dCB9M03q10vvwzUsntxj1tdBK3k';

  /// HMAC-SHA256 key used to verify gate responses and the cached entitlement.
  /// MUST byte-for-byte match the secret in `_gate_hmac()` in the SQL file.
  /// ⚠️ Change this to a fresh random value in BOTH places for production.
  static const String hmacSecret =
      '95ee072bcc2bd55251c4b0bd0485ca910f0c2ffccfa3dd1f1787b1cfca6d614b';

  /// "Expiring soon" window before the expiry date (staff nudge only; shoppers
  /// are unaffected until the device is actually blocked).
  static const Duration warnWindow = Duration(days: 30);

  /// Offline grace: how long a previously-approved device keeps working without
  /// a fresh server verdict. Generous on purpose — these are dedicated kiosks
  /// (NQuire 750 etc.), not personal phones, and a legit unit is normally online
  /// so it re-validates every [refreshInterval] (6h). The long window only
  /// covers genuine internet outages; it does NOT weaken enforcement for an
  /// online device, which is revoked within 6h regardless. The only abuse it
  /// permits is deliberately keeping a unit offline — which is visible in the
  /// dashboard (its `last_seen_at` stops updating) and ends at the deadline.
  static const Duration offlineGrace = Duration(days: 14);

  /// How often the kiosk re-validates with the licence server.
  static const Duration refreshInterval = Duration(hours: 6);

  /// Billing contact shown to staff in the Licence section.
  static const String billingContact = 'account@touch.co.zw';

  /// True once real credentials are filled in (otherwise the licence layer is
  /// dormant and the app behaves as before — always active).
  static bool get configured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('YOUR-PROJECT') &&
      supabaseAnonKey.isNotEmpty &&
      supabaseAnonKey != 'YOUR-ANON-KEY';
}
