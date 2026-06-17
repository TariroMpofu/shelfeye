/// iVend product identity for lookup. Defensive JSON parsing ported from
/// StockRoom: id/name/code/barcode and UOM id resolved via a priority list,
/// with `_barcodeUOMId` (injected from the outer GetProductByBarCode envelope)
/// taking precedence.
library;

import 'dart:convert';
import 'dart:typed_data';

class Product {
  final String id;
  final String name;
  final String? code;
  final String? barcode;
  final String? baseUomId;
  final String? uomGroupId;

  /// Product Group (e.g. "BEVERAGES"). Required on the result screen — sourced
  /// from iVend `ProductGroupId`.
  final String? productGroup;
  final Uint8List? imageBytes;

  const Product({
    required this.id,
    required this.name,
    this.code,
    this.barcode,
    this.baseUomId,
    this.uomGroupId,
    this.productGroup,
    this.imageBytes,
  });

  /// Pack size extracted from the name when present (e.g. "AQUACLEAR 500ML" →
  /// "500 ml", "LIFE 1L" → "1 L"). Returns null when no size token is found, so
  /// the UI can omit the pack badge gracefully.
  String? get pack {
    final m = RegExp(
      r'(\d+(?:\.\d+)?)\s*(ML|L|KG|G|CL|MG)\b',
      caseSensitive: false,
    ).firstMatch(name);
    if (m == null) return null;
    final qty = m.group(1)!;
    final unit = m.group(2)!.toLowerCase();
    // Litres/kilograms read better uppercase; millilitres/grams lowercase.
    final display = (unit == 'l' || unit == 'kg') ? unit.toUpperCase() : unit;
    return '$qty $display';
  }

  bool get isValid => id.isNotEmpty && name.toLowerCase() != 'unknown';

  /// Same product with image bytes attached, preserving all other fields.
  Product withImage(Uint8List? bytes) => Product(
        id: id,
        name: name,
        code: code,
        barcode: barcode,
        baseUomId: baseUomId,
        uomGroupId: uomGroupId,
        productGroup: productGroup,
        imageBytes: bytes,
      );

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = (json['Id'] ?? json['ProductId'] ?? json['id'] ?? '').toString();
    final name =
        (json['Description'] ??
                json['ProductName'] ??
                json['Name'] ??
                json['name'] ??
                '')
            .toString()
            .trim();
    final code = (json['ProductCode'] ?? json['Code'] ?? json['Id'])
        ?.toString();
    final barcode = (json['BarCode'] ?? json['Barcode'] ?? json['barcode'])
        ?.toString();

    const uomIdFields = [
      '_barcodeUOMId', // injected from the outer BarcodeProduct.UOMId
      'InventoryUOMId',
      'UOMId',
      'UomId',
      'DefaultUOMId',
      'SaleUOMId',
      'BaseUOMId',
      'StockUOMId',
    ];
    String? baseUomId;
    for (final f in uomIdFields) {
      final v = json[f]?.toString();
      if (v != null && v.isNotEmpty) {
        baseUomId = v;
        break;
      }
    }

    const groupFields = [
      'UOMGroupId',
      'UomGroupId',
      'UOMGroupKey',
      'UomGroupKey',
      'UOMGroup',
    ];
    String? uomGroupId;
    for (final f in groupFields) {
      final v = json[f]?.toString();
      if (v != null && v.isNotEmpty) {
        uomGroupId = v;
        break;
      }
    }

    final pg = (json['ProductGroupId'] ?? json['ProductGroup'])?.toString();
    final productGroup = (pg != null && pg.isNotEmpty) ? pg : null;

    Uint8List? imageBytes;
    final imageBase64 =
        json['ImageBase64String'] ??
        (json['ProductImage'] is Map<String, dynamic>
            ? json['ProductImage']['ImageBase64String']
            : null);
    if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
      try {
        imageBytes = base64Decode(imageBase64.toString());
      } catch (_) {
        imageBytes = null;
      }
    }

    return Product(
      id: id,
      name: name.isEmpty ? 'Unknown' : name,
      code: code,
      barcode: barcode,
      baseUomId: baseUomId,
      uomGroupId: uomGroupId,
      productGroup: productGroup,
      imageBytes: imageBytes,
    );
  }
}
