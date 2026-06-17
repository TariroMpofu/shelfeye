import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import '../../core/app_theme.dart';
import '../../models/app_config.dart';
import '../../models/currency.dart';
import '../../models/licence.dart';
import '../../models/store_ref.dart';
import '../../services/app_state.dart';
import '../../services/licence_constants.dart';
import '../../utils/log_buffer.dart';
import 'confirm_dialog.dart';
import 'kiosk_widgets.dart';

enum _TestState { untested, running, ok, failed }

/// Staff-only configuration: connection, store, currency. All connection /
/// store-fetch / save logic is preserved from the original config screen.
class SettingsScreen extends StatefulWidget {
  final VoidCallback onExit;
  const SettingsScreen({super.key, required this.onExit});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  _TestState _test = _TestState.untested;
  String? _testMsg;
  List<StoreRef> _stores = [];
  StoreRef? _selectedStore;
  String _currencyCode = 'USD';

  // Credentials lock: once an API user + password are saved they're greyed out
  // (a tech taps "Change" to edit them again).
  bool _credsLocked = false;

  // Store lock: the store chosen at initial setup is fixed and never changes —
  // a tech must explicitly "Relicense" (distinct from renewing) to swap it.
  bool _storeLocked = false;
  String _lockedStoreName = '';
  String _lockedStoreId = '';
  String _lockedStoreKey = '';

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().config;
    if (c != null) {
      _hostCtrl.text = c.host;
      _userCtrl.text = c.apiUserId;
      _passCtrl.text = c.apiPassword;
      if (c.currencyCode.isNotEmpty) _currencyCode = c.currencyCode;
      _credsLocked =
          c.apiUserId.trim().isNotEmpty && c.apiPassword.trim().isNotEmpty;
      _storeLocked = c.storeId.trim().isNotEmpty;
      _lockedStoreId = c.storeId;
      _lockedStoreName = c.storeName;
      _lockedStoreKey = c.storeKey;
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _endpoint {
    final ip = _hostCtrl.text.trim();
    return ip.isEmpty
        ? 'http://{host}/iVendAPI/iVendAPI.svc/WebAPI'
        : 'http://$ip/iVendAPI/iVendAPI.svc/WebAPI';
  }

  bool get _canSave =>
      _hostCtrl.text.trim().isNotEmpty &&
      _userCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.trim().isNotEmpty;

  Future<void> _testConnection() async {
    setState(() {
      _test = _TestState.running;
      _testMsg = null;
      _stores = [];
      _selectedStore = null;
    });
    final cfg = AppConfig(
      host: _hostCtrl.text.trim(),
      apiUserId: _userCtrl.text.trim(),
      apiPassword: _passCtrl.text.trim(),
    );
    final api = ApiClient(cfg);
    final ping = await api.ping();
    if (!mounted) return;
    if (!ping.ok) {
      setState(() {
        _test = _TestState.failed;
        _testMsg = ping.errorMessage ?? 'Connection failed';
      });
      api.dispose();
      return;
    }
    try {
      final raw = await api.getJson('/GetAllStores/');
      final list = <StoreRef>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) list.add(StoreRef.fromJson(e));
        }
      } else if (raw is Map<String, dynamic>) {
        list.add(StoreRef.fromJson(raw));
      }
      if (!mounted) return;
      final savedStoreId = context.read<AppState>().config?.storeId;
      StoreRef? selected;
      if (savedStoreId != null && savedStoreId.isNotEmpty) {
        for (final store in list) {
          if (store.storeLookupId == savedStoreId) {
            selected = store;
            break;
          }
        }
      }
      selected ??= list.length == 1 ? list.first : null;
      setState(() {
        _test = _TestState.ok;
        _stores = list;
        _selectedStore = selected;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _test = _TestState.ok;
        _testMsg =
            'Connected, but stores could not be loaded: ${e.userMessage}';
      });
    } finally {
      api.dispose();
    }
  }

  /// Resolve the store's active price list name (for the ribbon). Best-effort:
  /// returns '' on any failure so saving still succeeds.
  Future<String> _resolvePriceListName(AppConfig cfg) async {
    if (cfg.storeId.isEmpty) return '';
    final api = ApiClient(cfg);
    try {
      final store = await api.getJson('/GetStore/', query: {'id': cfg.storeId});
      var priceListId = '';
      if (store is Map<String, dynamic>) {
        priceListId = (store['PriceListId'] ?? '').toString();
        if (priceListId.isEmpty) {
          final coll = store['StorePriceListCollection'];
          if (coll is List) {
            for (final e in coll) {
              if (e is Map<String, dynamic> &&
                  e['IsDeleted'] != true &&
                  e['IsActive'] != false) {
                priceListId = (e['PriceListId'] ?? '').toString();
                if (priceListId.isNotEmpty) break;
              }
            }
          }
        }
      }
      if (priceListId.isEmpty) return '';
      // Prefer the friendly PriceListName; fall back to the id.
      try {
        final pl = await api.getJson(
          '/GetPriceList/',
          query: {'id': priceListId, 'getMatrixList': 'false'},
        );
        if (pl is Map<String, dynamic>) {
          final name = (pl['PriceListName'] ?? '').toString();
          if (name.isNotEmpty) return name;
        }
      } catch (_) {}
      return priceListId;
    } catch (_) {
      return '';
    } finally {
      api.dispose();
    }
  }

  /// Confirm (red) before unlocking the store — relicensing reassigns this
  /// device's store and clears the current selection.
  Future<void> _confirmRelicense() async {
    final ok = await ConfirmDialog.show(
      context,
      icon: Icons.swap_horiz,
      iconBg: AppTheme.danger.withValues(alpha: 0.12),
      iconColor: AppTheme.danger,
      title: 'Change store?',
      message: 'Relicensing unlocks the store and clears the current '
          'selection. Test the connection and pick a store again before '
          'saving.',
      info: [
        (Icons.store_outlined, 'STORE · $_lockedStoreName'),
      ],
      confirmLabel: 'Change store',
      destructive: true,
    );
    if (ok && mounted) {
      setState(() {
        _storeLocked = false;
        _selectedStore = null;
      });
    }
  }

  /// Send the on-device diagnostics log (last 7 days) via the OS share sheet.
  Future<void> _sendFeedback() async {
    final size = MediaQuery.of(context).size;
    try {
      final file = await LogBuffer.buildCombinedFile();
      if (!mounted) return;
      await Share.shareXFiles(
        [
          XFile(file.path,
              mimeType: 'text/plain', name: 'pricecheck-logs.txt'),
        ],
        subject: 'PriceCheck diagnostics log',
        sharePositionOrigin:
            Rect.fromLTWH(0, 0, size.width, size.height / 2),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open share sheet: $e')),
      );
    }
  }

  Future<void> _save() async {
    // When the store is locked, keep the existing assignment; otherwise use the
    // newly selected store.
    final existing = context.read<AppState>().config;
    final useLocked = _storeLocked && _lockedStoreId.isNotEmpty;
    var cfg = AppConfig(
      host: _hostCtrl.text.trim(),
      apiUserId: _userCtrl.text.trim(),
      apiPassword: _passCtrl.text.trim(),
      storeId: useLocked
          ? _lockedStoreId
          : (_selectedStore?.storeLookupId ?? ''),
      cashCustomerId: useLocked
          ? (existing?.cashCustomerId ?? '')
          : (_selectedStore?.cashCustomerId ?? ''),
      storeName: useLocked ? _lockedStoreName : (_selectedStore?.name ?? ''),
      storeKey: useLocked ? _lockedStoreKey : (_selectedStore?.key ?? ''),
      currencyCode: _currencyCode,
    );
    cfg = cfg.copyWith(priceListName: await _resolvePriceListName(cfg));
    if (!mounted) return;
    final ok = await context.read<AppState>().saveConfig(cfg);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Saved' : 'Saved (credentials may not persist)'),
      ),
    );
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.line2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: widget.onExit,
                icon: const Icon(
                  Icons.chevron_left,
                  color: AppTheme.inkSoft,
                  size: 26,
                ),
                label: Text(
                  'Exit',
                  style: AppTheme.sans(fontSize: 18, color: AppTheme.inkSoft),
                ),
              ),
              Text(
                'Settings',
                style: AppTheme.sans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacingEm: -0.02,
                ),
              ),
              // Send diagnostics log (bug report).
              SizedBox(
                width: 90,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: _sendFeedback,
                    tooltip: 'Send diagnostics log',
                    icon: const Icon(Icons.bug_report_outlined,
                        color: AppTheme.inkSoft, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ConnBanner(state: _test, message: _testMsg),
                    const SizedBox(height: 30),
                    _GroupTitle('Server'),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Host',
                      child: _Input(
                        controller: _hostCtrl,
                        hint: 'e.g. 192.168.100.144',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c) {
                        final stack = c.maxWidth < 520;
                        final user = _Field(
                          label: 'API user',
                          child: _Input(
                            controller: _userCtrl,
                            hint: 'api',
                            enabled: !_credsLocked,
                            onChanged: (_) => setState(() {}),
                          ),
                        );
                        final pass = _Field(
                          label: 'API password',
                          child: _Input(
                            controller: _passCtrl,
                            obscure: _obscure,
                            enabled: !_credsLocked,
                            onChanged: (_) => setState(() {}),
                            suffix: _credsLocked
                                ? null
                                : GestureDetector(
                                    onTap: () =>
                                        setState(() => _obscure = !_obscure),
                                    child: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 22,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                          ),
                        );
                        if (stack) {
                          return Column(
                            children: [user, const SizedBox(height: 16), pass],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: user),
                            const SizedBox(width: 16),
                            Expanded(child: pass),
                          ],
                        );
                      },
                    ),
                    if (_credsLocked)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _credsLocked = false),
                          icon: const Icon(
                            Icons.lock_open_outlined,
                            size: 18,
                            color: AppTheme.accent,
                          ),
                          label: Text(
                            'Change credentials',
                            style: AppTheme.sans(
                              fontSize: 14,
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.paper2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _endpoint,
                        style: AppTheme.mono(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _GroupTitle('Store & pricing'),
                    const SizedBox(height: 8),
                    if (_storeLocked) ...[
                      _LockedStoreCard(
                        name: _lockedStoreName.isNotEmpty
                            ? _lockedStoreName
                            : _lockedStoreId,
                        storeId: _lockedStoreId,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _confirmRelicense,
                          icon: const Icon(
                            Icons.swap_horiz,
                            size: 18,
                            color: AppTheme.danger,
                          ),
                          label: Text(
                            'Relicense — change store',
                            style: AppTheme.sans(
                              fontSize: 14,
                              color: AppTheme.danger,
                            ),
                          ),
                        ),
                      ),
                    ] else if (_stores.isEmpty)
                      Text(
                        'Test the connection to load stores.',
                        style: AppTheme.sans(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      )
                    else
                      ..._stores.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StoreOption(
                            store: s,
                            selected: _selectedStore?.key == s.key,
                            onTap: () => setState(() => _selectedStore = s),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    _GroupTitle('Currency display'),
                    const SizedBox(height: 8),
                    Text(
                      'Shown next to every price. iVend exposes only the '
                      'currency GUID per store, so select the region currency '
                      'here.',
                      style: AppTheme.sans(fontSize: 14, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 14),
                    _CurrencyGrid(
                      selected: _currencyCode,
                      onSelect: (c) => setState(() => _currencyCode = c),
                    ),
                    // Only after the device has an actual verdict — hidden during
                    // first-time setup so it can't show a premature "Active".
                    if (context.watch<AppState>().licenceService.enabled &&
                        context.watch<AppState>().licenceVerified) ...[
                      const SizedBox(height: 30),
                      _GroupTitle('Licence & status'),
                      const SizedBox(height: 12),
                      const _LicenceSection(),
                    ],
                    const SizedBox(height: 30),
                    // Actions scroll with the form rather than occupying a fixed
                    // footer — frees vertical space on short landscape screens.
                    Row(
                      children: [
                        Expanded(
                          child: KButton(
                            label: _test == _TestState.running
                                ? 'Testing…'
                                : 'Test connection',
                            kind: KButtonKind.ghost,
                            xl: true,
                            enabled: _test != _TestState.running && _canSave,
                            onPressed: _testConnection,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: KButton(
                            label: 'Save & exit',
                            icon: Icons.check,
                            kind: KButtonKind.primary,
                            xl: true,
                            enabled: _canSave,
                            onPressed: _save,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnBanner extends StatelessWidget {
  final _TestState state;
  final String? message;
  const _ConnBanner({required this.state, this.message});

  @override
  Widget build(BuildContext context) {
    final ok = state == _TestState.ok;
    final failed = state == _TestState.failed;
    final label = switch (state) {
      _TestState.running => 'Testing connection…',
      _TestState.ok => message ?? 'Connected',
      _TestState.failed => message ?? 'Connection failed',
      _TestState.untested => 'Not tested',
    };
    final color = ok
        ? AppTheme.accent
        : (failed ? AppTheme.danger : AppTheme.inkSoft);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: ok ? AppTheme.accentWash : AppTheme.paper2,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: ok ? AppTheme.accentLine : AppTheme.line),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check : (failed ? Icons.error_outline : Icons.wifi),
            size: 22,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTheme.sans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Staff-only licence status card (behind the PIN). Tier-coloured; never shown
/// to shoppers. "Renew" re-checks the server for an extended expiry.
class _LicenceSection extends StatelessWidget {
  const _LicenceSection();

  // Tier palette (from the design spec).
  static const _emerald = Color(0xFF1F7A52);
  static const _emeraldWash = Color(0xFFE9F3EE);
  static const _amber = Color(0xFFB07D22);
  static const _amberWash = Color(0xFFF7EFDC);
  static const _ink = Color(0xFF1B1A16);

  String _fmtDate(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')} '
            '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.year}';

  /// Staff-readable label + detail for a blocked (paused) verdict.
  static (String, String) _blocked(String reason) {
    switch (reason) {
      case 'device_limit_reached':
        return (
          'Device limit reached',
          "This store's device allowance is full. Deactivate another device "
              'or raise the limit, then re-check.'
        );
      case 'entitlement_revoked':
        return (
          'Device slot revoked',
          'The allowance was reduced and this device lost its slot. Raise the '
              'limit or free a slot, then re-check.'
        );
      case 'licence_expired':
        return (
          'Subscription expired',
          'Renew the subscription to restore the price checker immediately.'
        );
      case 'store_inactive':
        return ('Store deactivated',
            'This store has been deactivated. Contact billing.');
      case 'store_not_found':
        return ('Store not registered',
            "This store isn't registered for licensing yet. Contact billing.");
      case 'device_inactive':
        return ('Device deactivated',
            'This device was deactivated. Reactivate it or contact billing.');
      case 'emulator_blocked':
        return ('Emulator blocked',
            "Emulators aren't permitted for this store.");
      case 'offline_grace_expired':
      case 'offline_no_cache':
        return (
          "Can't verify this device",
          'This device has not reached the licence server within the allowed '
              'offline window. Connect to the internet to re-verify.'
        );
      default:
        return ('Price check paused',
            'Renew to restore the price checker immediately.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lic = state.licence;
    final tier = state.licenceTier;
    final now = DateTime.now();
    final storeId = state.licenceStoreId; // GUID used for licensing
    final storeName = state.config?.storeName ?? '';

    Future<void> renew() async {
      await state.licenceService.refresh(storeId, storeName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Licence re-checked.')));
    }

    late Color bg, fg;
    late IconData icon;
    late String title, chip, body;
    String? actionLabel;
    String? footnote;
    final dark = tier == LicenceTier.paused;

    switch (tier) {
      case LicenceTier.active:
      case LicenceTier.lapsedInGrace: // unreachable in strict mode
        bg = _emeraldWash;
        fg = _emerald;
        icon = Icons.check_circle_outline;
        title = 'Active';
        chip = lic.validUntil == null ? 'No expiry' : '${lic.daysToExpiry(now)} days';
        body = lic.validUntil == null
            ? 'This device is licensed. Everything running normally.'
            : 'Renews ${_fmtDate(lic.validUntil)}. Everything running normally.';
        break;
      case LicenceTier.expiringSoon:
        bg = _amberWash;
        fg = _amber;
        icon = Icons.info_outline;
        title = 'Renewal due soon';
        chip = '${lic.daysToExpiry(now)} days';
        body = 'Renew before ${_fmtDate(lic.validUntil)} to avoid '
            'interruption. Customers are unaffected.';
        actionLabel = 'Renew now';
        break;
      case LicenceTier.paused:
        final (t, d) = _blocked(lic.reason);
        bg = _ink;
        fg = Colors.white;
        icon = Icons.pause_circle_outline;
        title = t;
        chip = 'Paused';
        body = "Customers now see the neutral 'short break' screen. $d";
        actionLabel = 'Re-check & restore';
        footnote = 'Reversible the moment this device is approved.';
        break;
    }

    final onCard = dark ? Colors.white : _ink;
    final muted = dark ? Colors.white70 : AppTheme.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(
              color: dark ? _ink : fg.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: dark ? Colors.white : fg, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.sans(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: onCard,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.12)
                          : fg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Text(
                      chip,
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : fg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: AppTheme.sans(fontSize: 15, color: onCard, height: 1.4),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    _LicenceButton(
                      label: actionLabel,
                      // On the dark paused card fg is white, so the fill would
                      // be a blank white pill — flip to white fill + ink text.
                      color: dark ? Colors.white : fg,
                      textColor: dark ? _ink : Colors.white,
                      onTap: renew,
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        'Billing: ${LicenceConstants.billingContact}',
                        style: AppTheme.mono(fontSize: 12, color: muted),
                      ),
                    ),
                  ],
                ),
              ],
              if (footnote != null) ...[
                const SizedBox(height: 10),
                Text(
                  footnote,
                  style: AppTheme.mono(fontSize: 12, color: muted),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Fail-open status row — a connectivity gap is NOT expiry. While the
        // server is unreachable the device runs on its cached approval.
        if (!state.licenceServerReachable && lic.allowed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _emeraldWash,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            child: Text(
              'Licence server unreachable — running on the last approval '
              '(offline grace: ${LicenceConstants.offlineGrace.inHours}h).',
              style: AppTheme.sans(fontSize: 13, color: _emerald),
            ),
          ),
        const SizedBox(height: 10),
        // Meta: this device + store, for support.
        Text(
          'Device ${state.licenceService.deviceModel.isNotEmpty ? state.licenceService.deviceModel : '—'}'
          ' (${state.licenceService.deviceLabel.isNotEmpty ? state.licenceService.deviceLabel : '????'})'
          '  ·  store $storeId'
          '  ·  last verified ${_fmtDate(lic.lastVerifiedAt)}',
          style: AppTheme.mono(fontSize: 11, color: AppTheme.faint),
        ),
      ],
    );
  }
}

class _LicenceButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _LicenceButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: AppTheme.sans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTheme.mono(
      fontSize: 13,
      color: AppTheme.muted,
      letterSpacingEm: 0.1,
    ),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;
  const _Field({required this.label, required this.child});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTheme.sans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.inkSoft,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  const _Input({
    required this.controller,
    this.hint,
    this.obscure = false,
    this.enabled = true,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        // Greyed when disabled (e.g. credentials locked after setup).
        color: enabled ? AppTheme.surface : AppTheme.paper2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              enabled: enabled,
              onChanged: onChanged,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTheme.mono(fontSize: 18, color: AppTheme.faint),
              ),
              style: AppTheme.mono(
                fontSize: 18,
                color: enabled ? AppTheme.ink : AppTheme.muted,
              ),
            ),
          ),
          if (suffix != null) ...[const SizedBox(width: 8), suffix!],
        ],
      ),
    );
  }
}

/// The locked store assigned at setup — fixed unless "Relicense" is tapped.
class _LockedStoreCard extends StatelessWidget {
  final String name;
  final String storeId;
  const _LockedStoreCard({required this.name, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.paper2,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: AppTheme.line, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.store_outlined, size: 22, color: AppTheme.inkSoft),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.sans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'store $storeId',
                  style: AppTheme.mono(fontSize: 13, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 18, color: AppTheme.faint),
        ],
      ),
    );
  }
}

class _StoreOption extends StatelessWidget {
  final StoreRef store;
  final bool selected;
  final VoidCallback onTap;
  const _StoreOption({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentWash : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.line,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppTheme.accent : AppTheme.faint,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: AppTheme.sans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${store.storeLookupId} · cash cust ${store.cashCustomerId}',
                    style: AppTheme.mono(fontSize: 13, color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _CurrencyGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const minCol = 220.0;
        final cols = (c.maxWidth / minCol).floor().clamp(1, 3);
        final cardW = (c.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Currency.all.values.map((cur) {
            final sel = cur.code == selected;
            return SizedBox(
              width: cardW,
              child: GestureDetector(
                onTap: () => onSelect(cur.code),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.accentWash : AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(
                      color: sel ? AppTheme.accent : AppTheme.line,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          cur.symbol.trim().isEmpty
                              ? cur.code
                              : cur.symbol.trim(),
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          cur.label,
                          style: AppTheme.sans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        cur.format(2.5) ?? '',
                        style: AppTheme.mono(
                          fontSize: 14,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
