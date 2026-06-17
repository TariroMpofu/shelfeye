import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'kiosk_widgets.dart';

/// Blocks shoppers from Settings. 4-digit PIN; wrong PIN shakes + clears.
/// Demo PIN `1234` (replace with real staff auth/secret in production).
class PinGate extends StatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback onCancel;
  const PinGate({super.key, required this.onUnlock, required this.onCancel});

  static const String pinCode = '1234';

  @override
  State<PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<PinGate> with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _err = false;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _push(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _err = false;
      _pin += d;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (_pin == PinGate.pinCode) {
          widget.onUnlock();
        } else {
          setState(() {
            _err = true;
            _pin = '';
          });
          _shake.forward(from: 0);
        }
      });
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.chevron_left,
                  color: AppTheme.inkSoft, size: 26),
              label: Text('Back',
                  style: AppTheme.sans(fontSize: 18, color: AppTheme.inkSoft)),
            ),
          ),
          Expanded(
            child: FitScreen(
              padding: const EdgeInsets.only(bottom: 24),
              maxContentWidth: 400,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.line, width: 1.5),
                      ),
                      child: const Icon(Icons.lock_outline,
                          size: 34, color: AppTheme.inkSoft),
                    ),
                    const SizedBox(height: 18),
                    Text('Staff access',
                        style: AppTheme.sans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacingEm: -0.02,
                        )),
                    const SizedBox(height: 6),
                    Text('Enter the 4-digit PIN to open settings',
                        style: AppTheme.sans(
                            fontSize: 18, color: AppTheme.inkSoft)),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (_, child) {
                        final dx = _err
                            ? 8 *
                                (1 - _shake.value) *
                                (_shake.value < 0.5 ? -1 : 1)
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (i) {
                          final filled = i < _pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 9),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? AppTheme.ink : Colors.transparent,
                              border: Border.all(
                                color: filled ? AppTheme.ink : AppTheme.faint,
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 20,
                      child: _err
                          ? Text('Incorrect PIN — try again',
                              style: AppTheme.sans(
                                  fontSize: 15, color: AppTheme.danger))
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _PinPad(onKey: _push, onBackspace: _backspace),
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  const _PinPad({required this.onKey, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    Widget key(Widget child, VoidCallback? onTap) => _PinKey(onTap: onTap, child: child);
    return SizedBox(
      width: 84 * 3 + 14 * 2,
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
            key(
              Text(k,
                  style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.w500)),
              () => onKey(k),
            ),
          const SizedBox(width: 84, height: 84),
          key(
            Text('0',
                style: AppTheme.mono(fontSize: 26, fontWeight: FontWeight.w500)),
            () => onKey('0'),
          ),
          key(
            const Icon(Icons.chevron_left, size: 26, color: AppTheme.inkSoft),
            onBackspace,
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PinKey({required this.child, this.onTap});

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
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
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: _down ? AppTheme.paper2 : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.line, width: 1.5),
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
