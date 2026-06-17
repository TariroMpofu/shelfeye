/// Region currency configuration. Mirrors the handoff's currency contract:
/// `{ code, label, symbol, pos, dec }`. Prices are formatted through [format];
/// the price hero uses [split] to size the symbol / integer / fraction parts.
class Currency {
  final String code;
  final String label;
  final String symbol;
  final bool symbolBefore; // pos: 'before' | 'after'
  final int dec;

  const Currency({
    required this.code,
    required this.label,
    required this.symbol,
    this.symbolBefore = true,
    this.dec = 2,
  });

  /// Region presets for our markets: Botswana, Namibia, South Africa, Zambia,
  /// Zimbabwe (multi-currency: ZiG + USD).
  static const Map<String, Currency> all = {
    'USD': Currency(code: 'USD', label: 'US Dollar', symbol: r'$'),
    'ZWG': Currency(code: 'ZWG', label: 'Zimbabwe Gold (ZiG)', symbol: 'ZiG '),
    'ZAR': Currency(code: 'ZAR', label: 'South Africa Rand', symbol: 'R'),
    'BWP': Currency(code: 'BWP', label: 'Botswana Pula', symbol: 'P'),
    'NAD': Currency(code: 'NAD', label: 'Namibia Dollar', symbol: r'N$'),
    'ZMW': Currency(code: 'ZMW', label: 'Zambia Kwacha', symbol: 'K'),
  };

  static const Currency usd = Currency(
    code: 'USD',
    label: 'US Dollar',
    symbol: r'$',
  );

  /// Resolve a saved code to a known currency, defaulting to USD.
  static Currency byCode(String? code) => all[code ?? ''] ?? usd;

  /// Full formatted price (grouped, fixed decimals) or null when no value.
  String? format(double? value) {
    if (value == null) return null;
    final fixed = value.toStringAsFixed(dec);
    final parts = fixed.split('.');
    final grouped = _group(parts[0]);
    final n = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
    return symbolBefore ? '$symbol$n' : '$n$symbol';
  }

  /// Split a value into { symbol, int, frac } for the big price hero display.
  MoneyParts? split(double? value) {
    if (value == null) return null;
    final fixed = value.toStringAsFixed(dec);
    final parts = fixed.split('.');
    return MoneyParts(
      symbol: symbol.trim(),
      integer: _group(parts[0]),
      fraction: parts.length > 1 ? parts[1] : '',
    );
  }

  /// Thousands grouping for the integer part (e.g. 12345 → 12,345).
  static String _group(String intDigits) {
    final neg = intDigits.startsWith('-');
    final digits = neg ? intDigits.substring(1) : intDigits;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return neg ? '-$buf' : buf.toString();
  }
}

class MoneyParts {
  final String symbol;
  final String integer;
  final String fraction;
  const MoneyParts({
    required this.symbol,
    required this.integer,
    required this.fraction,
  });
}

/// A currency the shopper can display prices in, plus the FX rate from the base
/// currency (base prices × [rate]). The base currency itself has rate 1.
class DisplayCurrency {
  final Currency currency;
  final double rate;
  final bool isBase;
  const DisplayCurrency(this.currency, this.rate, {this.isBase = false});

  String get code => currency.code;

  /// Format a base-currency value into this display currency.
  String? format(double? base) =>
      base == null ? null : currency.format(base * rate);

  /// Split a base-currency value for the big price hero.
  MoneyParts? split(double? base) =>
      base == null ? null : currency.split(base * rate);
}
