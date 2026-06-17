import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/app_theme.dart';
import '../../models/currency.dart';
import '../../models/product_lookup_result.dart';
import '../../models/uom_option.dart';
import 'kiosk_widgets.dart';

/// The core screen: price instantly, plus pack-size comparison. Price is the
/// hero and the only accent use above the fold.
class ResultScreen extends StatelessWidget {
  final ProductLookupResult result;

  /// Selected display currency (+ FX rate). Base prices are multiplied by its
  /// rate and formatted with its symbol.
  final DisplayCurrency money;

  /// What the shopper actually scanned/typed (iVend doesn't echo a barcode on
  /// the product, so this is the only source of the scanned value).
  final String scannedCode;
  final VoidCallback onScanAnother;
  final VoidCallback onSearch;

  const ResultScreen({
    super.key,
    required this.result,
    required this.money,
    required this.scannedCode,
    required this.onScanAnother,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final p = result.product;
    final baseUom = result.baseUom;
    final basePrice = result.basePrice;
    final analysis = _analyse(result);
    // The comparison grid only shows UOMs that actually have a price — a "price
    // not set" card is noise. The grid appears when 2+ UOMs are priced.
    final pricedUoms = result.uoms.where((u) => u.price != null).toList();
    final hasUoms = pricedUoms.length > 1;

    // Proportional layout driven by information priority (price → name →
    // variants → image → metadata → actions). Landscape uses two columns so the
    // width does real work (price dominant left; image + dense variants right);
    // narrow/portrait stacks. Everything fits the viewport — no scroll.
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final wide = w >= 620; // landscape tablet → two columns
        final compact = !wide || h < 430;
        final gap = compact ? 10.0 : 16.0;

        final headline = _Headline(
          pack: p.pack,
          group: p.productGroup,
          name: p.name,
          code: p.code ?? p.id,
          barcode: p.barcode,
          scannedCode: scannedCode,
          compact: compact,
        );
        final price = _PriceHero(
          baseUomName: baseUom?.name ?? '—',
          money: result.priced ? money.split(basePrice) : null,
          priced: result.priced,
          compact: compact,
        );
        final uomCards = _UomCards(
          uoms: pricedUoms,
          money: money,
          bestId: analysis.bestId,
          priced: result.priced,
          compact: compact,
        );

        // Image is low priority (#4): modest, sized off the smaller dimension.
        final mediaSide =
            (h * 0.2).clamp(56.0, wide ? 132.0 : 104.0).toDouble();
        final media = _ProductMedia(result: result, side: mediaSide);

        // Actions are #6 — comfortable touch targets, never dominant. Stack on
        // very narrow widths so the labels never get crushed.
        final stackActions = w < 480;
        final scanBtn = KButton(
          label: 'Scan another item',
          icon: Icons.qr_code_scanner,
          kind: KButtonKind.scan,
          onPressed: onScanAnother,
        );
        final searchBtn = KButton(
          label: 'Search',
          icon: Icons.search,
          kind: KButtonKind.ghost,
          onPressed: onSearch,
        );
        final actions = stackActions
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [scanBtn, SizedBox(height: gap), searchBtn],
              )
            : Row(
                children: [
                  Expanded(flex: 2, child: scanBtn),
                  const SizedBox(width: 12),
                  Expanded(child: searchBtn),
                ],
              );

        final Widget body;
        if (wide && hasUoms) {
          // Two columns: name + dominant price (left), image + variant grid
          // (right).
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headline,
                    SizedBox(height: gap),
                    Expanded(child: price),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(alignment: Alignment.topRight, child: media),
                    SizedBox(height: gap),
                    Expanded(child: uomCards),
                  ],
                ),
              ),
            ],
          );
        } else if (wide) {
          // Single price on a wide screen: image in the header, the price as a
          // contained, centered card with equal margins (no empty column).
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headline),
                  const SizedBox(width: 20),
                  media,
                ],
              ),
              SizedBox(height: gap),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (w * 0.6).clamp(360.0, 760.0).toDouble(),
                    ),
                    child: price,
                  ),
                ),
              ),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headline),
                  // Image is #4 priority — drop it on very narrow phones so the
                  // name/metadata have room.
                  if (w >= 440) ...[const SizedBox(width: 12), media],
                ],
              ),
              SizedBox(height: gap),
              Expanded(flex: hasUoms ? 5 : 10, child: price),
              if (hasUoms) ...[
                SizedBox(height: gap),
                Expanded(flex: 6, child: uomCards),
              ],
            ],
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, compact ? 6 : 10, 20, compact ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: body),
              SizedBox(height: gap),
              actions,
            ],
          ),
        );
      },
    );
  }
}

class _Analysis {
  final String? bestId;
  const _Analysis(this.bestId);
}

/// Best value = lowest per-base-unit price among priced UOMs (only when more
/// than one is priced).
_Analysis _analyse(ProductLookupResult r) {
  String? bestId;
  double? bestPer;
  var pricedCount = 0;
  for (final u in r.uoms) {
    if (u.price == null) continue;
    pricedCount++;
    final per = u.price! / (u.baseUnitsPer == 0 ? 1 : u.baseUnitsPer);
    if (bestPer == null || per < bestPer) {
      bestPer = per;
      bestId = u.id;
    }
  }
  return _Analysis(pricedCount > 1 ? bestId : null);
}

class _Headline extends StatelessWidget {
  final String? pack;
  final String? group;
  final String name;
  final String code;
  final String? barcode;
  final String scannedCode;

  final bool compact;

  const _Headline({
    required this.pack,
    required this.group,
    required this.name,
    required this.code,
    required this.barcode,
    required this.scannedCode,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final nameSize =
        (w * 0.046).clamp(compact ? 22.0 : 30.0, compact ? 34.0 : 52.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (pack != null) _PackBadge(pack!),
            // Product Group (required field). iVend has no friendlier name than
            // the group code, so the chip carries it; no separate category line.
            if (group != null) _GroupChip(group!),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
        // Always show the full product name (wraps as needed; FitScreen scales).
        Text(
          name,
          style: AppTheme.sans(
            fontSize: nameSize,
            fontWeight: FontWeight.w800,
            color: AppTheme.ink,
            letterSpacingEm: -0.03,
            height: 1.05,
          ),
        ),
        SizedBox(height: compact ? 8 : 14),
        // Product code (Id) and the scanned barcode, side by side. iVend doesn't
        // store a barcode on the product, so the barcode shown is what was
        // scanned/typed (only when it differs from the code).
        _IdentifierRow(code: code, barcode: _barcodeToShow()),
      ],
    );
  }

  /// The barcode value to display: the product's own barcode if iVend has one,
  /// otherwise the scanned/typed value when it differs from the code.
  String? _barcodeToShow() {
    if (barcode != null && barcode!.trim().isNotEmpty) return barcode!.trim();
    final s = scannedCode.trim();
    if (s.isNotEmpty && s.toUpperCase() != code.trim().toUpperCase()) return s;
    return null;
  }
}

class _IdentifierRow extends StatelessWidget {
  final String code;
  final String? barcode;
  const _IdentifierRow({required this.code, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _IdentifierChip(
          icon: Icons.tag,
          label: 'CODE',
          value: code,
        ),
        if (barcode != null)
          _IdentifierChip(
            glyph: true,
            label: 'BARCODE',
            value: barcode!,
          ),
      ],
    );
  }
}

class _IdentifierChip extends StatelessWidget {
  final IconData? icon;
  final bool glyph;
  final String label;
  final String value;
  const _IdentifierChip({
    this.icon,
    this.glyph = false,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph)
          const BarcodeGlyph(size: 18, color: AppTheme.muted)
        else if (icon != null)
          Icon(icon, size: 16, color: AppTheme.muted),
        const SizedBox(width: 7),
        Text(
          '$label ',
          style: AppTheme.mono(
            fontSize: 12,
            color: AppTheme.faint,
            letterSpacingEm: 0.08,
          ),
        ),
        Text(
          value,
          style: AppTheme.mono(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.inkSoft,
            letterSpacingEm: 0.02,
          ),
        ),
      ],
    );
  }
}

class _PackBadge extends StatelessWidget {
  final String pack;
  const _PackBadge(this.pack);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        pack,
        style: AppTheme.mono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.paper,
          letterSpacingEm: 0.03,
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  final String group;
  const _GroupChip(this.group);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.paper2,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 15, color: AppTheme.accent),
          const SizedBox(width: 7),
          Text(
            group,
            style: AppTheme.sans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductMedia extends StatelessWidget {
  final ProductLookupResult result;
  final double side;
  const _ProductMedia({required this.result, required this.side});

  @override
  Widget build(BuildContext context) {
    final bytes = result.product.imageBytes;
    final child = bytes != null && bytes.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: Image.memory(bytes, fit: BoxFit.contain),
          )
        : _placeholder();

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: bytes != null ? AppTheme.surface : AppTheme.paper2,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _placeholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: SvgPicture.asset(
        'assets/brand/svg/product-placeholder.svg',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _PriceHero extends StatelessWidget {
  final String baseUomName;
  final MoneyParts? money;
  final bool priced;
  final bool compact;

  const _PriceHero({
    required this.baseUomName,
    required this.money,
    required this.priced,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 22 : 32,
        vertical: compact ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.line, width: 1.5),
        boxShadow: AppTheme.shadow,
      ),
      // Laid out at a fixed design size and scaled to the hero box with
      // BoxFit.contain — the price grows to fill (bold, legible) and never
      // overflows, at any screen size.
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRICE · PER ${baseUomName.toUpperCase()}',
              style: AppTheme.mono(
                fontSize: 16,
                color: AppTheme.muted,
                letterSpacingEm: 0.1,
              ),
            ),
            const SizedBox(height: 8),
            if (money != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(money!.symbol,
                      style: AppTheme.sans(
                        fontSize: 55,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        letterSpacingEm: -0.04,
                      )),
                  Text(money!.integer,
                      style: AppTheme.monoTabular(
                        fontSize: 120,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accent,
                        letterSpacingEm: -0.04,
                      )),
                  if (money!.fraction.isNotEmpty)
                    Text('.${money!.fraction}',
                        style: AppTheme.monoTabular(
                          fontSize: 60,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accent,
                          letterSpacingEm: -0.04,
                        )),
                ],
              )
            else
              Text(
                priced ? 'Price not available' : 'No store configured',
                style: AppTheme.sans(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UomCards extends StatelessWidget {
  final List<UomOption> uoms;
  final DisplayCurrency money;
  final String? bestId;
  final bool priced;
  final bool compact;
  const _UomCards({
    required this.uoms,
    required this.money,
    required this.bestId,
    required this.priced,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const g = 12.0;
        // Equal grid that fills the full width (Expanded columns) and the full
        // available height (Expanded rows), so cards are uniform and edge-to-
        // edge on every device.
        final maxCols = uoms.length <= 1 ? 1 : (uoms.length <= 2 ? 2 : 4);
        final fit = (c.maxWidth / (compact ? 150 : 200)).floor();
        final cols = fit.clamp(1, maxCols);
        final rowsCount = (uoms.length / cols).ceil();

        Widget cell(int i) => i < uoms.length
            ? Expanded(
                child: _UomCard(
                  uom: uoms[i],
                  money: money,
                  isBest: uoms[i].id == bestId,
                  priced: priced,
                  compact: compact,
                ),
              )
            : const Expanded(child: SizedBox());

        final rows = <Widget>[];
        for (var r = 0; r < rowsCount; r++) {
          if (r > 0) rows.add(const SizedBox(height: g));
          final cells = <Widget>[];
          for (var col = 0; col < cols; col++) {
            if (col > 0) cells.add(const SizedBox(width: g));
            cells.add(cell(r * cols + col));
          }
          rows.add(Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          ));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class _UomCard extends StatelessWidget {
  final UomOption uom;
  final DisplayCurrency money;
  final bool isBest;
  final bool priced;
  final bool compact;
  const _UomCard({
    required this.uom,
    required this.money,
    required this.isBest,
    required this.priced,
    this.compact = false,
  });

  static String _qtyLabel(double q) =>
      q == q.truncate() ? q.toInt().toString() : q.toStringAsFixed(2);

  Widget _tag(String text, bool best) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: best ? AppTheme.accent : AppTheme.paper2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTheme.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: best ? Colors.white : AppTheme.muted,
          letterSpacingEm: 0.05,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNa = uom.price == null;
    final qty = uom.baseUnitsPer;
    final perUnit = uom.price != null && qty > 0 ? uom.price! / qty : null;
    final priceText = money.format(uom.price);
    final perText = money.format(perUnit);

    final card = Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: isBest ? AppTheme.accentWash : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: isNa
            ? null
            : Border.all(
                color: isBest ? AppTheme.accentLine : AppTheme.line,
                width: 1.5,
              ),
      ),
      // The card is laid out at a fixed design size and scaled to the cell with
      // BoxFit.contain. The price is the dominant element so it fills the card;
      // the name/qty lines are secondary.
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      uom.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacingEm: -0.01,
                      ),
                    ),
                  ),
                  if (uom.isBase) ...[const SizedBox(width: 6), _tag('BASE', false)],
                  if (isBest) ...[const SizedBox(width: 6), _tag('BEST', true)],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                uom.isBase
                    ? 'Single unit'
                    : '${_qtyLabel(qty)} × single'
                        '${perText != null ? '  ·  $perText/unit' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mono(fontSize: 12, color: AppTheme.muted),
              ),
              const SizedBox(height: 6),
              isNa
                  ? Text('Price not set',
                      style: AppTheme.mono(fontSize: 16, color: AppTheme.faint))
                  : Text(
                      priceText ?? '',
                      style: AppTheme.monoTabular(
                        fontSize: 50,
                        fontWeight: FontWeight.w700,
                        color: isBest ? AppTheme.accent : AppTheme.ink,
                        letterSpacingEm: -0.02,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );

    return Opacity(
      opacity: isNa ? 0.6 : 1,
      child: isNa
          ? CustomPaint(
              foregroundPainter:
                  _DashedRectPainter(AppTheme.line, AppTheme.radius),
              child: card,
            )
          : card,
    );
  }
}

/// Dashed rounded-rect border for unpriced UOM cards.
class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedRectPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}
