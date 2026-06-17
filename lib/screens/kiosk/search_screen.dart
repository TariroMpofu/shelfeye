import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'kiosk_widgets.dart';

/// Manual fallback to type a barcode / product code. Secondary to scanning.
class SearchScreen extends StatefulWidget {
  final bool scanning;
  final VoidCallback onBack;
  final VoidCallback onScan;
  final ValueChanged<String> onSubmit;

  const SearchScreen({
    super.key,
    required this.scanning,
    required this.onBack,
    required this.onScan,
    required this.onSubmit,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _q => _ctrl.text.trim();

  void _setText(String v) {
    _ctrl.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
    setState(() {});
  }

  void _submit() {
    if (_q.isNotEmpty) widget.onSubmit(_q);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final headingSize = (w * 0.034).clamp(24.0, 34.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(label: 'Back', onTap: widget.onBack),
          Expanded(
            child: FitScreen(
              padding: const EdgeInsets.only(bottom: 20),
              maxContentWidth: 720,
              child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter a barcode or product code',
                        textAlign: TextAlign.center,
                        style: AppTheme.sans(
                          fontSize: headingSize,
                          fontWeight: FontWeight.w700,
                          letterSpacingEm: -0.02,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _SearchField(
                        controller: _ctrl,
                        onClear: () => _setText(''),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 22),
                      _Keypad(
                        onKey: (k) => _setText('${_ctrl.text}$k'),
                        onBackspace: () {
                          final t = _ctrl.text;
                          if (t.isNotEmpty) {
                            _setText(t.substring(0, t.length - 1));
                          }
                        },
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, c) {
                          final stack = c.maxWidth < 520;
                          final scan = KButton(
                            label: widget.scanning ? 'Scanning…' : 'Scan instead',
                            icon: Icons.qr_code_scanner,
                            kind: KButtonKind.scan,
                            xl: true,
                            enabled: !widget.scanning,
                            onPressed: widget.onScan,
                          );
                          final show = KButton(
                            label: 'Show price',
                            icon: Icons.arrow_forward,
                            iconTrailing: true,
                            kind: KButtonKind.primary,
                            xl: true,
                            enabled: _q.isNotEmpty,
                            onPressed: _submit,
                          );
                          if (stack) {
                            return Column(
                              children: [
                                scan,
                                const SizedBox(height: 14),
                                show,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: scan),
                              const SizedBox(width: 14),
                              Expanded(child: show),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;

  const _SearchField({
    required this.controller,
    required this.onClear,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.line, width: 2),
        boxShadow: AppTheme.shadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.muted, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              // No OS soft keyboard: the on-screen keypad and the hardware
              // wedge are the only inputs. readOnly + canRequestFocus:false
              // keeps the wedge listener focused.
              readOnly: true,
              canRequestFocus: false,
              showCursor: false,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'e.g. P0000001',
                hintStyle: AppTheme.mono(fontSize: 30, color: AppTheme.faint),
              ),
              style: AppTheme.mono(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: AppTheme.ink,
                letterSpacingEm: 0.02,
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, color: AppTheme.muted, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  const _Keypad({required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'P', '0', '⌫'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.0,
        children: keys.map((k) {
          final isFn = k == '⌫';
          return _Key(
            label: k,
            isFn: isFn,
            onTap: () => isFn ? onBackspace() : onKey(k),
          );
        }).toList(),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  final String label;
  final bool isFn;
  final VoidCallback onTap;
  const _Key({required this.label, required this.isFn, required this.onTap});

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          decoration: BoxDecoration(
            color: _down ? AppTheme.paper2 : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTheme.mono(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: widget.isFn ? AppTheme.inkSoft : AppTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BackButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.chevron_left, color: AppTheme.inkSoft, size: 26),
        label: Text(
          label,
          style: AppTheme.sans(fontSize: 18, color: AppTheme.inkSoft),
        ),
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.only(left: 12, right: 18),
        ),
      ),
    );
  }
}
