/// One UOM choice for a product, with its conversion to the base unit and an
/// optional resolved price.
///
/// Conversion (from GetUOMGroup): `alternateQuantity` alternate units equal
/// `baseQuantity` base units, so one alternate unit = baseQuantity/alternateQuantity
/// base units. The base UOM itself is 1:1.
class UomOption {
  final String id;
  final String name;
  final bool isBase;
  final double baseQuantity;
  final double alternateQuantity;
  final double? price;

  const UomOption({
    required this.id,
    required this.name,
    required this.isBase,
    this.baseQuantity = 1,
    this.alternateQuantity = 1,
    this.price,
  });

  /// Base units contained in one of this UOM (e.g. 1 Pack = 6 EA → 6).
  double get baseUnitsPer {
    if (isBase) return 1;
    if (alternateQuantity == 0) return 1;
    return baseQuantity / alternateQuantity;
  }

  UomOption withPrice(double? p) => UomOption(
        id: id,
        name: name,
        isBase: isBase,
        baseQuantity: baseQuantity,
        alternateQuantity: alternateQuantity,
        price: p,
      );
}
