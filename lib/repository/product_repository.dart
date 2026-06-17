import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../core/result.dart';
import '../models/app_config.dart';
import '../models/product.dart';
import '../models/product_lookup_result.dart';
import '../models/uom_option.dart';

/// Orchestrates the full lookup against documented endpoints only:
///   GetProductByBarCode → (fallback) GetProduct → GetUOMGroup, with prices
///   read from the store's GetPriceList (cached per store). Image and price
///   list load concurrently with UOM resolution. Pure Dart, no Flutter —
///   unit-testable. Returns a [Result] so the UI never sees a raw throw.
class ProductRepository {
  final ApiClient _api;
  final AppConfig _config;
  ProductRepository(this._api, this._config);

  static const _fastTimeout = Duration(seconds: 8);

  // Per-store caches. The repository is rebuilt whenever the store/config
  // changes (see AppState._rebuild), so these live exactly as long as they're
  // valid — repeat lookups in the same store reuse them.
  Future<List<Map<String, dynamic>>?>? _matrixCache;
  final Map<String, Uint8List?> _imageCache = {};

  /// The store price list, loaded at most once per store. Shared across all
  /// lookups so repeat searches skip GetStore + GetPriceList.
  Future<List<Map<String, dynamic>>?> _priceMatrix() =>
      _matrixCache ??= _loadPriceMatrix();

  /// Starts loading the price list in the background so the first lookup
  /// doesn't have to wait for it. Safe to call on app start / after config.
  void prewarm() {
    if (_config.canPrice) _priceMatrix();
  }

  Future<Result<ProductLookupResult>> lookup(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) return const Err('Enter a barcode or product code.');

    try {
      // 1) barcode → product (outer envelope UOMId injected as _barcodeUOMId)
      Product? product = await _byBarcode(code);
      // 2) fallback: product code / id
      product ??= await _byId(code);

      if (product == null || !product.isValid) {
        return Err('No product found for "$code".');
      }

      // The barcode envelope is usually enough; only fetch the full product
      // when the UOM group is missing.
      product = await _enrich(product);

      // Image and price list are independent of UOM resolution — fetch them
      // concurrently instead of blocking the chain on each.
      final imageFuture = _loadProductImage(product);
      final priced = _config.canPrice;
      final matrixFuture = priced
          ? _priceMatrix()
          : Future<List<Map<String, dynamic>>?>.value(null);

      // 3) UOMs (group when present, else the single base UOM)
      final uoms = await _resolveUoms(product);

      // 4) prices per UOM (only when a store is configured)
      final pricedUoms = priced
          ? _priceAll(product, uoms, await matrixFuture ?? const [])
          : uoms;
      product = await imageFuture;

      return Ok(
        ProductLookupResult(product: product, uoms: pricedUoms, priced: priced),
      );
    } on ApiException catch (e) {
      return Err(e.userMessage);
    } catch (e) {
      return Err('Lookup failed: $e');
    }
  }

  Future<Product?> _byBarcode(String code) async {
    final raw = await _api.getJson(
      '/GetProductByBarCode/',
      query: {'barCode': code, 'vendorId': ''},
      timeout: _fastTimeout,
    );
    if (raw is Map<String, dynamic> && raw['Product'] is Map<String, dynamic>) {
      final map = Map<String, dynamic>.from(raw['Product'] as Map);
      final outerUom = raw['UOMId']?.toString();
      if (outerUom != null && outerUom.isNotEmpty) {
        map['_barcodeUOMId'] = outerUom;
      }
      return Product.fromJson(map);
    }
    final map = _extractProductMap(raw);
    return map == null ? null : Product.fromJson(map);
  }

  Future<Product?> _byId(String code) async {
    final raw = await _api.getJson(
      '/GetProduct/',
      query: {'id': code},
      timeout: _fastTimeout,
    );
    final map = _extractProductMap(raw);
    return map == null ? null : Product.fromJson(map);
  }

  /// Fills in the UOM group from the full GetProduct record when the barcode
  /// envelope didn't carry it. The UOM group is what we actually need to price
  /// every UOM; when it's already present we skip this round trip entirely.
  /// Keeps the original product on any failure so lookup still succeeds.
  Future<Product> _enrich(Product p) async {
    if (p.uomGroupId != null && p.uomGroupId!.isNotEmpty) {
      return p;
    }
    try {
      final raw = await _api.getJson(
        '/GetProduct/',
        query: {'id': p.id},
        timeout: _fastTimeout,
      );
      final map = _extractProductMap(raw);
      if (map == null) return p;
      final full = Product.fromJson(map);
      return Product(
        id: p.id,
        name: p.name,
        code: p.code ?? full.code,
        barcode: p.barcode ?? full.barcode,
        baseUomId: (p.baseUomId != null && p.baseUomId!.isNotEmpty)
            ? p.baseUomId
            : full.baseUomId,
        uomGroupId: (p.uomGroupId != null && p.uomGroupId!.isNotEmpty)
            ? p.uomGroupId
            : full.uomGroupId,
        productGroup: p.productGroup ?? full.productGroup,
        imageBytes: p.imageBytes ?? full.imageBytes,
      );
    } catch (e) {
      debugPrint('enrich failed: $e');
      return p;
    }
  }

  Map<String, dynamic>? _extractProductMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['Product'] is Map<String, dynamic>) {
        return raw['Product'] as Map<String, dynamic>;
      }
      if (raw.containsKey('Id') ||
          raw.containsKey('ProductId') ||
          raw.containsKey('Description')) {
        return raw;
      }
    }
    if (raw is List && raw.isNotEmpty) return _extractProductMap(raw.first);
    return null;
  }

  Future<Product> _loadProductImage(Product product) async {
    if (product.imageBytes != null) return product;
    // Reuse a previously fetched image for this product (cached per store).
    if (_imageCache.containsKey(product.id)) {
      return product.withImage(_imageCache[product.id]);
    }
    try {
      final raw = await _api.getJson(
        '/GetProductImage/',
        query: {'id': product.id},
      );
      if (raw is Map<String, dynamic>) {
        // Parse only the image, then attach it to the existing product so we
        // don't lose its UOM group / base UOM (the image response lacks them).
        final imageOnly = Product.fromJson({
          ...raw,
          'Id': product.id,
          'Description': product.name,
        });
        _imageCache[product.id] = imageOnly.imageBytes;
        if (imageOnly.imageBytes != null) {
          return product.withImage(imageOnly.imageBytes);
        }
      }
    } catch (_) {
      // Ignore image fetch failures; product lookup still succeeds.
    }
    return product;
  }

  /// base + alternate UOMs with conversion. Falls back to the product's single
  /// base UOM when there's no real group.
  Future<List<UomOption>> _resolveUoms(Product p) async {
    final gid = p.uomGroupId;
    if (gid != null && gid.isNotEmpty && gid != '0') {
      try {
        final raw = await _api.getJson('/GetUOMGroup/', query: {'id': gid});
        final list = raw is List ? raw : (raw != null ? [raw] : const []);
        final out = <UomOption>[];
        final seen = <String>{};
        var baseAdded = false;
        for (final item in list) {
          if (item is! Map<String, dynamic>) continue;
          if (item['ToDelete'] == true) continue;
          final baseId = (item['BaseUOMId'] ?? '').toString();
          final baseDesc = (item['BaseUOMDescription'] ?? '').toString();
          final altId = (item['AlternateUOMId'] ?? '').toString();
          final altDesc = (item['AlternateUOMDescription'] ?? '').toString();
          final baseQty = _toD(item['BaseQuantity']);
          final altQty = _toD(item['AlternateQuantity']);
          if (!baseAdded && baseId.isNotEmpty && seen.add(baseId)) {
            out.add(
              UomOption(
                id: baseId,
                name: baseDesc.isNotEmpty ? baseDesc : baseId,
                isBase: true,
              ),
            );
            baseAdded = true;
          }
          if (altId.isNotEmpty && seen.add(altId)) {
            out.add(
              UomOption(
                id: altId,
                name: altDesc.isNotEmpty ? altDesc : altId,
                isBase: false,
                baseQuantity: baseQty == 0 ? 1 : baseQty,
                alternateQuantity: altQty == 0 ? 1 : altQty,
              ),
            );
          }
        }
        if (out.isNotEmpty) return out;
      } catch (e) {
        debugPrint('UOM group failed: $e');
      }
    }
    // Single UOM fallback.
    final uid = p.baseUomId ?? '';
    return [UomOption(id: uid, name: uid.isEmpty ? '—' : uid, isBase: true)];
  }

  /// Prices every UOM straight from [matrix] (the store price list) — no extra
  /// round trips. iVend stores a distinct user-defined price per UOM
  /// (PriceUOMMatrixList) plus a product-level base price (PriceMatrixList).
  /// Each UOM shows its OWN price — never one derived from another UOM — so an
  /// unpriced UOM has no price (shown as —).
  List<UomOption> _priceAll(
    Product p,
    List<UomOption> uoms,
    List<Map<String, dynamic>> matrix,
  ) {
    return uoms
        .map((u) => u.withPrice(_matchUomPrice(
              matrix,
              productId: p.id,
              uomId: u.id,
              isBase: u.isBase,
            )))
        .toList();
  }

  /// Resolves the store's price list and returns its flattened matrix (each
  /// entry has at least `ProductId`, `UOMId`, `Price`). In iVend the price list
  /// is attached to the store, not the customer. Returns null on any failure so
  /// pricing degrades gracefully.
  Future<List<Map<String, dynamic>>?> _loadPriceMatrix() async {
    try {
      final priceListId = await _resolveStorePriceListId();
      if (priceListId == null || priceListId.isEmpty) return null;

      final raw = await _api.getJson(
        '/GetPriceList/',
        query: {'id': priceListId, 'getMatrixList': 'true'},
      );
      if (raw is! Map<String, dynamic>) return null;

      final out = <Map<String, dynamic>>[];
      for (final key in const ['PriceUOMMatrixList', 'PriceMatrixList']) {
        final list = raw[key];
        if (list is List) {
          for (final e in list) {
            if (e is Map<String, dynamic>) out.add(e);
          }
        }
      }
      return out;
    } catch (e) {
      debugPrint('price list failed: $e');
      return null;
    }
  }

  /// The store's active price list id: the direct `PriceListId`, else the first
  /// active (non-deleted) entry in `StorePriceListCollection`.
  Future<String?> _resolveStorePriceListId() async {
    final store = await _api.getJson(
      '/GetStore/',
      query: {'id': _config.storeId},
    );
    if (store is! Map<String, dynamic>) return null;

    final direct = (store['PriceListId'] ?? '').toString();
    if (direct.isNotEmpty) return direct;

    final collection = store['StorePriceListCollection'];
    if (collection is List) {
      for (final e in collection) {
        if (e is! Map<String, dynamic>) continue;
        if (e['IsDeleted'] == true) continue;
        if (e['IsActive'] == false) continue;
        final id = (e['PriceListId'] ?? '').toString();
        if (id.isNotEmpty) return id;
      }
    }
    return null;
  }

  /// This UOM's own user-defined price in the price matrix: an exact
  /// product + UOM entry (PriceUOMMatrixList). The base UOM may additionally
  /// fall back to the product-level entry (PriceMatrixList, no UOMId). Returns
  /// null when this UOM has no price configured — never another UOM's price.
  double? _matchUomPrice(
    List<Map<String, dynamic>> matrix, {
    required String productId,
    required String uomId,
    required bool isBase,
  }) {
    // Exact per-UOM price.
    if (uomId.isNotEmpty) {
      for (final e in matrix) {
        if ((e['ProductId'] ?? '').toString() != productId) continue;
        if ((e['UOMId'] ?? '').toString() != uomId) continue;
        final v = _toD(e['Price']);
        if (v != 0) return v;
      }
    }
    // Base UOM only: the product-level (UOMId-less) entry.
    if (isBase) {
      for (final e in matrix) {
        if ((e['ProductId'] ?? '').toString() != productId) continue;
        if ((e['UOMId'] ?? '').toString().isNotEmpty) continue;
        final v = _toD(e['Price']);
        if (v != 0) return v;
      }
    }
    return null;
  }

  static double _toD(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
}
