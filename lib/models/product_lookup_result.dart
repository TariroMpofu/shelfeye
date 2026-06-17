import 'product.dart';
import 'uom_option.dart';

/// The single object the repository returns for a lookup. The UI renders
/// straight from this.
class ProductLookupResult {
  final Product product;
  final List<UomOption> uoms;

  /// True when prices were resolved (a store is configured). When false, UOMs
  /// are shown without price.
  final bool priced;

  const ProductLookupResult({
    required this.product,
    required this.uoms,
    required this.priced,
  });

  UomOption? get baseUom {
    for (final u in uoms) {
      if (u.isBase) return u;
    }
    return uoms.isNotEmpty ? uoms.first : null;
  }

  double? get basePrice => baseUom?.price;
  bool get hasMultipleUoms => uoms.length > 1;
}
