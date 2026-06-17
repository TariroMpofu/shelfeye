import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

/// Persists config the StockRoom way: non-sensitive fields in SharedPreferences,
/// credentials in secure storage (Keychain/Keystore) with read-back verification.
class ConfigService {
  static const _key = 'shelfeye_config';
  static const _credKey = 'shelfeye_credentials_v1';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Returns true if credentials were verified in secure storage.
  Future<bool> save(AppConfig c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'host': c.host,
        'storeId': c.storeId,
        'cashCustomerId': c.cashCustomerId,
        'storeName': c.storeName,
        'storeKey': c.storeKey,
        'currencyCode': c.currencyCode,
        'priceListName': c.priceListName,
      }),
    );
    try {
      await _storage.write(
        key: _credKey,
        value: jsonEncode({'u': c.apiUserId, 'p': c.apiPassword}),
      );
      return (await _storage.read(key: _credKey)) != null;
    } catch (_) {
      return false;
    }
  }

  Future<AppConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    String u = '', p = '';
    try {
      final cred = await _storage.read(key: _credKey);
      if (cred != null) {
        final m = jsonDecode(cred) as Map<String, dynamic>;
        u = m['u'] as String? ?? '';
        p = m['p'] as String? ?? '';
      }
    } catch (_) {}
    return AppConfig(
      host: data['host'] as String? ?? '',
      apiUserId: u,
      apiPassword: p,
      storeId: data['storeId'] as String? ?? '',
      cashCustomerId: data['cashCustomerId'] as String? ?? '',
      storeName: data['storeName'] as String? ?? '',
      storeKey: data['storeKey'] as String? ?? '',
      currencyCode: (data['currencyCode'] as String?)?.isNotEmpty == true
          ? data['currencyCode'] as String
          : 'USD',
      priceListName: data['priceListName'] as String? ?? '',
    );
  }
}
