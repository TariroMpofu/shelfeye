import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../services/app_state.dart';
import '../../services/wedge_scanner.dart';
import 'idle_screen.dart';
import 'kiosk_bar.dart';
import 'not_found_screen.dart';
import 'paused_screen.dart';
import 'pin_gate.dart';
import 'result_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// Top-level kiosk shell. Holds the chrome bar (shopper screens only) and
/// switches between the five states driven by [AppState]. Input is the hardware
/// barcode wedge; an inactivity timer returns to the idle/attract screen.
class KioskShell extends StatefulWidget {
  const KioskShell({super.key});

  @override
  State<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends State<KioskShell> {
  /// Return to the attract screen after this long without interaction.
  static const _idleTimeout = Duration(minutes: 5);
  Timer? _idleTimer;
  KioskScreen? _lastScreen;

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  /// (Re)start the inactivity timer on shopper screens; cancel it elsewhere.
  void _bumpIdleTimer(KioskScreen screen) {
    _idleTimer?.cancel();
    final track = screen == KioskScreen.search ||
        screen == KioskScreen.result ||
        screen == KioskScreen.notFound;
    if (!track) return;
    _idleTimer = Timer(_idleTimeout, () {
      if (mounted) context.read<AppState>().goIdle();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final screen = state.screen;
    final size = MediaQuery.of(context).size;
    final showBar =
        screen != KioskScreen.pin && screen != KioskScreen.settings;
    // Licence paused → shopper flow is replaced by the calm "short break" screen.
    final paused = state.licencePaused;
    final isShopperScreen = screen == KioskScreen.idle ||
        screen == KioskScreen.search ||
        screen == KioskScreen.result ||
        screen == KioskScreen.notFound;
    // Capture wedge scans on shopper screens only — never while the admin is
    // entering a PIN/settings, and never while paused.
    final wedgeEnabled = isShopperScreen && !paused;

    // Only reset the inactivity timer when the screen actually changes — not on
    // every rebuild (e.g. the periodic connection ping), which would otherwise
    // keep deferring the auto-return to idle forever.
    if (screen != _lastScreen) {
      _lastScreen = screen;
      _bumpIdleTimer(screen);
    }

    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: Listener(
          // Any touch counts as activity and defers the auto-return to idle.
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _bumpIdleTimer(screen),
          child: Column(
            children: [
              if (showBar)
                KioskBar(
                  storeName: state.storeName,
                  subtitle: state.priceListLabel,
                  currencyOptions: state.currencyOptions,
                  selectedCurrency: state.selectedCurrencyIndex,
                  onSelectCurrency: state.selectCurrency,
                  showCurrency: !paused && screen == KioskScreen.result,
                  // Hide the connection state on the paused screen so it can't
                  // leak the cause.
                  showStatus: !(paused && isShopperScreen),
                  reachability: state.reachability,
                  isConfigured: state.isConfigured,
                  onTapStatus: state.pingServer,
                  showStore: size.width >= 520,
                  onSecretTap: state.goPin,
                ),
              Expanded(
                child: WedgeScanner(
                  enabled: wedgeEnabled,
                  onScan: (code) {
                    state.setScanning(true);
                    state.lookup(code);
                  },
                  child: (paused && isShopperScreen)
                      ? const PausedScreen()
                      : _body(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppState state) {
    switch (state.screen) {
      case KioskScreen.idle:
        return IdleScreen(
          scanning: state.scanning || state.status == LookupStatus.searching,
          onSearch: state.goSearch,
        );
      case KioskScreen.search:
        return SearchScreen(
          scanning: state.scanning,
          onBack: state.goIdle,
          onScan: state.goIdle,
          onSubmit: (q) => state.lookup(q),
        );
      case KioskScreen.result:
        final result = state.result;
        if (result == null) {
          return IdleScreen(scanning: false, onSearch: state.goSearch);
        }
        return ResultScreen(
          result: result,
          money: state.displayCurrency,
          scannedCode: state.query,
          onScanAnother: state.goIdle,
          onSearch: state.goSearch,
        );
      case KioskScreen.notFound:
        return NotFoundScreen(
          query: state.query,
          onScan: state.goIdle,
          onRetry: state.goSearch,
        );
      case KioskScreen.pin:
        return PinGate(
          onUnlock: state.goSettings,
          onCancel: state.goIdle,
        );
      case KioskScreen.settings:
        return SettingsScreen(onExit: state.goIdle);
    }
  }
}
