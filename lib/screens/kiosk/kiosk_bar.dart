import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/app_theme.dart';
import '../../models/currency.dart';
import '../../services/app_state.dart' show Reachability;

/// Shopper-facing top bar. The logo/wordmark is the hidden settings trigger:
/// 4 taps within 1.2s opens the PIN gate. No visible settings button.
class KioskBar extends StatefulWidget {
  final String storeName;

  /// Secondary line under the store name (price list name) — shown when there's
  /// only the base currency to display.
  final String subtitle;

  /// Display-currency options + which is selected. When more than one, the
  /// subtitle becomes a tappable dropdown that reprices everything.
  final List<DisplayCurrency> currencyOptions;
  final int selectedCurrency;
  final ValueChanged<int> onSelectCurrency;

  /// Show the currency dropdown (result screen only); elsewhere the subtitle
  /// stays the price list name.
  final bool showCurrency;

  /// Connection state for the tappable indicator. Grey when not configured,
  /// red when unreachable, green when reachable, spinner while checking.
  final Reachability reachability;
  final bool isConfigured;
  final VoidCallback onTapStatus;

  /// Hide the connection pill (e.g. the paused screen, so it can't leak why).
  final bool showStatus;

  final bool showStore;
  final VoidCallback onSecretTap;

  const KioskBar({
    super.key,
    required this.storeName,
    required this.subtitle,
    required this.currencyOptions,
    required this.selectedCurrency,
    required this.onSelectCurrency,
    required this.reachability,
    required this.isConfigured,
    required this.onTapStatus,
    required this.onSecretTap,
    this.showCurrency = false,
    this.showStatus = true,
    this.showStore = true,
  });

  @override
  State<KioskBar> createState() => _KioskBarState();
}

class _KioskBarState extends State<KioskBar> {
  final List<DateTime> _taps = [];

  void _onBrandTap() {
    final now = DateTime.now();
    _taps.removeWhere((t) => now.difference(t).inMilliseconds > 1200);
    _taps.add(now);
    if (_taps.length >= 4) {
      _taps.clear();
      widget.onSecretTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onBrandTap,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/brand/svg/pricecheck-mark.svg',
                  width: 42,
                  height: 42,
                ),
                const SizedBox(width: 12),
                Text(
                  'PriceCheck',
                  style: AppTheme.sans(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacingEm: -0.02,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              if (widget.showStore) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.storeName,
                      style: AppTheme.sans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    widget.showCurrency && widget.currencyOptions.length > 1
                        ? _CurrencyDropdown(
                            options: widget.currencyOptions,
                            selected: widget.selectedCurrency,
                            onSelect: widget.onSelectCurrency,
                          )
                        : Text(
                            widget.subtitle,
                            style: AppTheme.mono(
                              fontSize: 12,
                              color: AppTheme.muted,
                              letterSpacingEm: 0.04,
                            ),
                          ),
                  ],
                ),
                const SizedBox(width: 20),
              ],
              if (widget.showStatus)
                _StatusPill(
                  reachability: widget.reachability,
                  isConfigured: widget.isConfigured,
                  onTap: widget.onTapStatus,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tappable currency selector shown in the ribbon when more than one display
/// currency is available. Picking one reprices the whole result screen.
class _CurrencyDropdown extends StatelessWidget {
  final List<DisplayCurrency> options;
  final int selected;
  final ValueChanged<int> onSelect;
  const _CurrencyDropdown({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final sel = options[selected.clamp(0, options.length - 1)];
    return PopupMenuButton<int>(
      tooltip: 'Currency',
      onSelected: onSelect,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: AppTheme.surface,
      elevation: 10,
      shadowColor: const Color(0x22000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.line),
      ),
      itemBuilder: (_) => [
        for (var i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            height: 46,
            child: Row(
              children: [
                Text(
                  options[i].code,
                  style: AppTheme.mono(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    options[i].currency.label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sans(fontSize: 14, color: AppTheme.inkSoft),
                  ),
                ),
                if (i == selected) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.check, size: 18, color: AppTheme.accent),
                ],
              ],
            ),
          ),
      ],
      // Subtle tappable pill, matching the status indicator style.
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 3, 6, 3),
        decoration: BoxDecoration(
          color: AppTheme.paper2,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sel.code,
              style: AppTheme.mono(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.inkSoft,
                letterSpacingEm: 0.04,
              ),
            ),
            const Icon(Icons.expand_more, size: 16, color: AppTheme.muted),
          ],
        ),
      ),
    );
  }
}

/// Connection indicator. Grey when not configured / not yet checked, a spinner
/// while checking, red when unreachable, green when reachable. Tap to force a
/// fresh CheckAPIConnection ping (a red dot can be tapped to retry → green).
class _StatusPill extends StatelessWidget {
  final Reachability reachability;
  final bool isConfigured;
  final VoidCallback onTap;
  const _StatusPill({
    required this.reachability,
    required this.isConfigured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final checking = reachability == Reachability.checking;
    final (Color color, String label) = _resolve();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: checking ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: AppTheme.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (checking)
                const SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.6, color: AppTheme.muted),
                )
              else
                Container(
                  width: 9,
                  height: 9,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                  letterSpacingEm: 0.06,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String) _resolve() {
    if (!isConfigured) return (AppTheme.muted, 'NOT SET UP');
    switch (reachability) {
      case Reachability.reachable:
        return (AppTheme.accent, 'ONLINE');
      case Reachability.unreachable:
        return (AppTheme.danger, 'OFFLINE');
      case Reachability.checking:
        return (AppTheme.muted, 'CHECKING');
      case Reachability.unknown:
        return (AppTheme.muted, 'TAP TO CHECK');
    }
  }
}
