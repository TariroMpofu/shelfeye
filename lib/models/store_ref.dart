/// A store from GetAllStores.
/// `id` is the store identifier used by GetItemSalesPrice; `key` is the
/// internal GUID returned by the API.
/// `cashCustomerId` is the default retail customer for pricing.
class StoreRef {
  final String key;
  final String id;
  final String name;
  final String cashCustomerId;

  const StoreRef({
    required this.key,
    required this.id,
    required this.name,
    required this.cashCustomerId,
  });

  String get storeLookupId => id.isNotEmpty ? id : key;

  factory StoreRef.fromJson(Map<String, dynamic> j) => StoreRef(
    key: (j['Key'] ?? '').toString(),
    id: (j['Id'] ?? '').toString(),
    name: (j['Description'] ?? j['Id'] ?? 'Unknown store').toString(),
    cashCustomerId: (j['CashCustomerId'] ?? '').toString(),
  );
}
