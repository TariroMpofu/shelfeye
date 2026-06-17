import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shelfeye/models/currency.dart';
import 'package:shelfeye/models/product.dart';
import 'package:shelfeye/models/product_lookup_result.dart';
import 'package:shelfeye/models/uom_option.dart';
import 'package:shelfeye/screens/kiosk/idle_screen.dart';
import 'package:shelfeye/screens/kiosk/not_found_screen.dart';
import 'package:shelfeye/screens/kiosk/pin_gate.dart';
import 'package:shelfeye/screens/kiosk/result_screen.dart';
import 'package:shelfeye/screens/kiosk/search_screen.dart';

/// Required landscape viewports (logical px). The kiosk must fit every screen
/// in each of these with no overflow and no scrolling.
const _viewports = <Size>[
  Size(568, 320), // iPhone SE landscape (smallest supported)
  Size(812, 375), // iPhone 13 mini landscape
  Size(667, 375),
  Size(736, 414),
  Size(844, 390),
  Size(1024, 768), // iPad landscape
  Size(1180, 820), // iPad Air landscape
  Size(1366, 1024), // large tablet / desktop window
  // Portrait + small phone (layout must still fit, no scroll).
  Size(320, 568), // small phone portrait
  Size(390, 844), // phone portrait
  Size(768, 1024), // iPad portrait
  Size(800, 1280), // Android tablet portrait
];

ProductLookupResult _sampleResult() {
  const product = Product(
    id: 'P0000007',
    name: 'EXECUTIVE NOTEBOOK A5 100PAGE LONG NAME WRAP TEST',
    code: 'P0000007',
    barcode: '6001234567890',
    productGroup: 'STATIONERY',
  );
  const uoms = [
    UomOption(id: 'EA', name: 'EA', isBase: true, price: 3.0),
    UomOption(
        id: '6PK',
        name: '6PK',
        isBase: false,
        baseQuantity: 6,
        alternateQuantity: 1,
        price: 16.5),
    UomOption(
        id: '24PK',
        name: '24PK',
        isBase: false,
        baseQuantity: 24,
        alternateQuantity: 1),
    UomOption(
        id: '12PK',
        name: '12PK',
        isBase: false,
        baseQuantity: 12,
        alternateQuantity: 1),
  ];
  return const ProductLookupResult(product: product, uoms: uoms, priced: true);
}

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  final screens = <String, Widget>{
    'IdleScreen': IdleScreen(scanning: false, onSearch: () {}),
    'SearchScreen': SearchScreen(
      scanning: false,
      onBack: () {},
      onScan: () {},
      onSubmit: (_) {},
    ),
    'ResultScreen': ResultScreen(
      result: _sampleResult(),
      money: const DisplayCurrency(Currency.usd, 1, isBase: true),
      scannedCode: '6001234567890',
      onScanAnother: () {},
      onSearch: () {},
    ),
    'NotFoundScreen': NotFoundScreen(
      query: 'XYZ-NOT-A-REAL-CODE-123456',
      onScan: () {},
      onRetry: () {},
    ),
    'PinGate': PinGate(onUnlock: () {}, onCancel: () {}),
  };

  for (final entry in screens.entries) {
    for (final vp in _viewports) {
      testWidgets('${entry.key} @ ${vp.width.toInt()}x${vp.height.toInt()}',
          (tester) async {
        await _pumpAt(tester, vp, entry.value);
        // Any RenderFlex overflow or layout assertion surfaces here.
        expect(tester.takeException(), isNull,
            reason: '${entry.key} overflowed at ${vp.width}x${vp.height}');
      });
    }
  }
}
