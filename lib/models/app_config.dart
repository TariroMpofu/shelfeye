/// Server + credentials + (optional) store context for pricing.
/// Mirrors StockRoom's split: non-sensitive fields persist in SharedPreferences,
/// credentials in secure storage (see ConfigService).
class AppConfig {
  final String host;
  final String apiUserId;
  final String apiPassword;

  /// Store id (from GetAllStores `Id`, or fallback to `Key`) + its cash
  /// customer — needed for GetItemSalesPrice. Empty when no store is configured
  /// (lookup still works, just without price).
  final String storeId;
  final String cashCustomerId;
  final String storeName;

  /// The store's globally-unique GUID (GetAllStores `Key`). Used as the licence
  /// `store_id` (unique across iVend installs), while [storeId] stays the iVend
  /// lookup id used for pricing.
  final String storeKey;

  /// Region currency code shown next to prices (e.g. `USD`, `ZAR`, `KES`). Set
  /// manually in settings since iVend only exposes the currency GUID per store,
  /// with no documented GUID→code lookup. Defaults to `USD`.
  final String currencyCode;

  /// The store's active price list name, shown on the kiosk ribbon. Resolved
  /// from iVend at save time; empty when unknown.
  final String priceListName;

  const AppConfig({
    required this.host,
    required this.apiUserId,
    required this.apiPassword,
    this.storeId = '',
    this.cashCustomerId = '',
    this.storeName = '',
    this.storeKey = '',
    this.currencyCode = 'USD',
    this.priceListName = '',
  });

  bool get hasServer => host.isNotEmpty;
  bool get isConfigured =>
      host.isNotEmpty && apiUserId.isNotEmpty && apiPassword.isNotEmpty;
  bool get canPrice => storeId.isNotEmpty && cashCustomerId.isNotEmpty;

  /// Documented base URL shape (HTTP, WCF REST).
  String get apiBaseUrl => 'http://$host/iVendAPI/iVendAPI.svc/WebAPI';

  AppConfig copyWith({
    String? host,
    String? apiUserId,
    String? apiPassword,
    String? storeId,
    String? cashCustomerId,
    String? storeName,
    String? storeKey,
    String? currencyCode,
    String? priceListName,
  }) => AppConfig(
    host: host ?? this.host,
    apiUserId: apiUserId ?? this.apiUserId,
    apiPassword: apiPassword ?? this.apiPassword,
    storeId: storeId ?? this.storeId,
    cashCustomerId: cashCustomerId ?? this.cashCustomerId,
    storeName: storeName ?? this.storeName,
    storeKey: storeKey ?? this.storeKey,
    currencyCode: currencyCode ?? this.currencyCode,
    priceListName: priceListName ?? this.priceListName,
  );
}
