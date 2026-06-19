import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../core/result.dart';
import '../models/app_config.dart';
import '../models/currency.dart';
import '../models/licence.dart';
import '../models/product_lookup_result.dart';
import '../repository/product_repository.dart';
import 'config_service.dart';
import 'licence_service.dart';

enum LookupStatus { idle, searching, found, notFound, error }

enum Reachability { unknown, checking, reachable, unreachable }

/// Kiosk screen state machine (handoff): idle → (scan/search) → result /
/// notfound, plus pin → settings.
enum KioskScreen { idle, search, result, notFound, pin, settings }

/// App-wide state (provider). Holds config, builds the ApiClient + repository,
/// runs lookups with latest-wins guarding, and caches results for the session.
class AppState extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final LicenceService _licence = LicenceService();

  AppState() {
    // Re-render when the licence tier changes (shopper screen + staff section).
    _licence.addListener(notifyListeners);
  }

  AppConfig? _config;
  ApiClient? _api;
  ProductRepository? _repo;

  LookupStatus _status = LookupStatus.idle;
  String? _message;
  ProductLookupResult? _result;
  Reachability _reach = Reachability.unknown;
  String? _reachError;

  // Connection monitoring (mirrors StockRoom): a periodic health ping plus OS
  // network events, with the last-known state persisted so the ribbon shows
  // green/red immediately on launch.
  // Adaptive polling: relaxed while healthy, aggressive while offline so the
  // kiosk reconnects fast when the server/VPN comes back (an OS network event
  // won't fire if Wi-Fi stayed up but iVend was down).
  static const _pingIntervalOnline = Duration(minutes: 3);
  static const _pingIntervalOffline = Duration(seconds: 2);
  static const _onlineKey = 'shelfeye_last_online';
  Timer? _pingTimer;
  bool _pingRunning = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _connDebounce;
  DateTime? _lastConnPing;

  // Kiosk navigation + scan state.
  KioskScreen _screen = KioskScreen.idle;
  bool _scanning = false;
  String _query = '';

  final _cache = <String, ProductLookupResult>{};
  int _generation = 0;

  AppConfig? get config => _config;
  bool get isConfigured => _config?.isConfigured ?? false;
  LookupStatus get status => _status;
  String? get message => _message;
  ProductLookupResult? get result => _result;
  Reachability get reachability => _reach;

  KioskScreen get screen => _screen;
  bool get scanning => _scanning;
  String get query => _query;

  /// Online when the server is reachable (or not yet checked optimistically
  /// false until confirmed). Drives the top-bar status pill.
  bool get online => _reach == Reachability.reachable;

  /// Last connection error message (null when online/unknown).
  String? get reachError => _reachError;

  /// Base currency for price formatting (the price-list currency from config).
  Currency get currency => Currency.byCode(_config?.currencyCode);

  // ---- Multi-currency display (FX) ---------------------------------------
  // Base prices are in [currency]; shoppers can switch to any currency that has
  // an exchange rate for today (priceBase × rate).
  List<DisplayCurrency> _currencyOptions = const [];
  int _selectedCurrency = 0;

  /// All selectable display currencies (base first, then those with a rate).
  List<DisplayCurrency> get currencyOptions => _currencyOptions.isEmpty
      ? [DisplayCurrency(currency, 1, isBase: true)]
      : _currencyOptions;

  /// The currently selected display currency (+ its rate).
  DisplayCurrency get displayCurrency {
    final opts = currencyOptions;
    final i = _selectedCurrency.clamp(0, opts.length - 1);
    return opts[i];
  }

  bool get hasMultipleCurrencies => currencyOptions.length > 1;

  int get selectedCurrencyIndex =>
      _selectedCurrency.clamp(0, currencyOptions.length - 1);

  void selectCurrency(int index) {
    if (index < 0 || index >= currencyOptions.length) return;
    _selectedCurrency = index;
    notifyListeners();
  }

  // ---- Strict per-device licence ------------------------------------------
  /// The licence key for this store: the globally-unique GUID (`storeKey`),
  /// falling back to the lookup id for configs saved before the key was stored.
  String get _licenceStoreId {
    final k = _config?.storeKey ?? '';
    return k.isNotEmpty ? k : (_config?.storeId ?? '');
  }

  /// The store id used for licensing (GUID key). Exposed so the staff "re-check"
  /// uses the same id the device registered with.
  String get licenceStoreId => _licenceStoreId;

  LicenceService get licenceService => _licence;
  Licence get licence => _licence.licence;

  /// True once the device has an actual verdict (verified live or restored from
  /// cache). Used to hide the staff Licence card during first-time setup, before
  /// any check-in has happened, so it can't show a premature "Active".
  bool get licenceVerified => _licence.licence.lastVerifiedAt != null;
  LicenceTier get licenceTier => _licence.tier;
  bool get licencePaused => _licence.isPaused;
  bool get licenceServerReachable => _licence.serverReachable;

  String get storeName =>
      (_config?.storeName.isNotEmpty ?? false) ? _config!.storeName : 'No store';

  /// Ribbon subtitle: the store's price list name, falling back to the currency
  /// code when not yet resolved.
  String get priceListLabel {
    final pl = _config?.priceListName ?? '';
    return pl.isNotEmpty ? pl : currency.code;
  }

  // ---- Kiosk navigation ---------------------------------------------------
  void goIdle() {
    _screen = KioskScreen.idle;
    _scanning = false;
    // Reset to the base currency for the next shopper.
    _selectedCurrency = 0;
    notifyListeners();
  }

  void goSearch() {
    _screen = KioskScreen.search;
    // Reset to the base currency, same as "Scan another item", so each new
    // lookup starts from the store's base currency.
    _selectedCurrency = 0;
    notifyListeners();
  }

  void goPin() {
    _screen = KioskScreen.pin;
    notifyListeners();
  }

  void goSettings() {
    _screen = KioskScreen.settings;
    notifyListeners();
  }

  void setScanning(bool v) {
    _scanning = v;
    notifyListeners();
  }

  Future<void> loadConfig() async {
    _config = await _configService.load();
    _rebuild();
    // Restore the last-known online state so the ribbon shows green/red
    // immediately, before the first live ping resolves.
    await _loadPersistedOnline();
    notifyListeners();
    if (isConfigured) {
      _startReachabilityChecks();
      _startConnectivityMonitoring();
      loadCurrencyOptions();
      _licence.start(_licenceStoreId, _config!.storeName);
    }
  }

  Future<bool> saveConfig(AppConfig c) async {
    final ok = await _configService.save(c);
    _config = c;
    _cache.clear();
    _rebuild();
    _reach = Reachability.unknown;
    _reachError = null;
    _currencyOptions = const [];
    _selectedCurrency = 0;
    notifyListeners();
    if (isConfigured) {
      _startReachabilityChecks();
      _startConnectivityMonitoring();
      loadCurrencyOptions();
      _licence.start(_licenceStoreId, _config!.storeName);
    }
    return ok;
  }

  /// Loads display-currency options: the base currency (rate 1) plus every
  /// currency with an exchange rate for today (base price × rate). Best-effort;
  /// on failure only the base currency is offered.
  Future<void> loadCurrencyOptions() async {
    final api = _api;
    if (api == null) return;
    final base = DisplayCurrency(currency, 1, isBase: true);
    try {
      final today = DateTime.now();
      final eff = '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}T00:00:00';
      final raw = await api.getJson(
        '/GetExchangeRateByDate/',
        query: {'effectiveDate': eff},
      );
      final out = <DisplayCurrency>[base];
      if (raw is List) {
        for (final e in raw) {
          if (e is! Map<String, dynamic>) continue;
          final code = (e['CurrencyId'] ?? '').toString();
          final rate = _toD(e['Rate']);
          if (code.isEmpty || rate <= 0) continue;
          if (code.toUpperCase() == base.code.toUpperCase()) continue;
          // Use a known preset for the symbol; fall back to the code itself.
          final cur = Currency.all[code] ??
              Currency(code: code, label: code, symbol: '$code ');
          out.add(DisplayCurrency(cur, rate));
        }
      }
      _currencyOptions = out;
      if (_selectedCurrency >= _currencyOptions.length) _selectedCurrency = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('currency options failed: $e');
      _currencyOptions = [base];
      notifyListeners();
    }
  }

  static double _toD(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  void _rebuild() {
    _api?.dispose();
    final c = _config;
    if (c != null && c.isConfigured) {
      _api = ApiClient(c);
      _repo = ProductRepository(_api!, c);
      // Warm the price-list cache so the first lookup is fast.
      _repo!.prewarm();
    } else {
      _api = null;
      _repo = null;
    }
  }

  /// One health ping via CheckAPIConnection. Adaptive timeout: 8s when warm,
  /// 30s when cold/unknown (IIS app-pool can take 8-15s to spin up). Persists
  /// the resulting online state. Safe to call from anywhere.
  Future<bool> pingServer() async {
    if (_pingRunning) return _reach == Reachability.reachable;
    _pingRunning = true;
    try {
      final api = _api;
      if (api == null || !isConfigured) {
        _reach = Reachability.unknown;
        notifyListeners();
        return false;
      }
      final timeout = _reach == Reachability.reachable
          ? const Duration(seconds: 8)
          : const Duration(seconds: 30);
      _reach = Reachability.checking;
      notifyListeners();
      final r = await api.ping(timeout: timeout);
      _reach = r.ok ? Reachability.reachable : Reachability.unreachable;
      _reachError = r.ok ? null : r.errorMessage;
      await _persistOnline(r.ok);
      notifyListeners();
      // Load currency rates once we're online (e.g. server was down at startup).
      if (r.ok && _currencyOptions.length <= 1) loadCurrencyOptions();
      return r.ok;
    } finally {
      _pingRunning = false;
    }
  }

  void _startReachabilityChecks() {
    _pingTimer?.cancel();
    if (!isConfigured) return;
    // Resolve once now, then schedule the next check at an interval that adapts
    // to the outcome (fast while offline, relaxed while healthy).
    pingServer().then((_) => _scheduleNextPing());
  }

  /// One-shot timer that reschedules itself after each ping, picking the
  /// interval from the current reachability so a down server is retried every
  /// 15s until it returns, then backs off to 3 min once healthy.
  void _scheduleNextPing() {
    _pingTimer?.cancel();
    if (!isConfigured) return;
    final interval = _reach == Reachability.reachable
        ? _pingIntervalOnline
        : _pingIntervalOffline;
    _pingTimer = Timer(interval, () async {
      await pingServer();
      _scheduleNextPing();
    });
  }

  /// OS network events update reachability immediately: on loss → unreachable
  /// (no ping needed); on restore → a debounced ping so the health check stays
  /// authoritative. A 30s floor between connectivity pings avoids ping storms
  /// during Wi-Fi handover.
  void _startConnectivityMonitoring() {
    _connSub?.cancel();
    _connSub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasNetwork = results.any((r) => r != ConnectivityResult.none);
    if (!hasNetwork) {
      _connDebounce?.cancel();
      _connDebounce = null;
      if (_reach != Reachability.unreachable) {
        _reach = Reachability.unreachable;
        _reachError = 'No network connection.';
        _persistOnline(false);
        notifyListeners();
      }
      return;
    }
    final now = DateTime.now();
    if (_lastConnPing != null &&
        now.difference(_lastConnPing!) < const Duration(seconds: 30)) {
      return;
    }
    _connDebounce?.cancel();
    _connDebounce = Timer(const Duration(seconds: 2), () {
      _connDebounce = null;
      _lastConnPing = DateTime.now();
      pingServer();
    });
  }

  Future<void> _loadPersistedOnline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getBool(_onlineKey);
      if (last != null) {
        _reach = last ? Reachability.reachable : Reachability.unreachable;
      }
    } catch (_) {}
  }

  Future<void> _persistOnline(bool online) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onlineKey, online);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _connDebounce?.cancel();
    _connSub?.cancel();
    _licence.removeListener(notifyListeners);
    _licence.dispose();
    _api?.dispose();
    super.dispose();
  }

  void clear() {
    _status = LookupStatus.idle;
    _message = null;
    _result = null;
    notifyListeners();
  }

  Future<void> lookup(String code) async {
    final repo = _repo;
    if (repo == null) {
      _status = LookupStatus.error;
      _message = 'Not configured — open settings to add a server.';
      notifyListeners();
      return;
    }

    final gen = ++_generation;
    _query = code.trim();

    final cached = _cache[code.trim()];
    if (cached != null) {
      _status = LookupStatus.found;
      _result = cached;
      _message = null;
      _scanning = false;
      _screen = KioskScreen.result;
      notifyListeners();
      return;
    }

    _status = LookupStatus.searching;
    _message = null;
    _result = null;
    notifyListeners();

    final Result<ProductLookupResult> res = await repo.lookup(code);
    if (gen != _generation) return; // a newer lookup superseded this one

    _scanning = false;
    res.when(
      ok: (value) {
        _cache[code.trim()] = value;
        _result = value;
        _status = LookupStatus.found;
        _message = null;
        _screen = KioskScreen.result;
      },
      err: (m) {
        _result = null;
        // Distinguish "not found" from a real error for UI tone.
        if (m.startsWith('No product found')) {
          _status = LookupStatus.notFound;
        } else {
          _status = LookupStatus.error;
        }
        _message = m;
        _screen = KioskScreen.notFound;
      },
    );
    notifyListeners();
  }
}
