import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Captures hardware barcode-wedge input app-wide.
///
/// The kiosk's scanner is configured as a keyboard wedge ("Simulate keystroke"
/// + "Output enter-event"), so each scan arrives as a burst of key events
/// terminated by Enter. We buffer the characters and fire [onScan] on Enter —
/// no focused text field and no camera required, so a scan works on any screen.
class WedgeScanner extends StatefulWidget {
  final bool enabled;
  final ValueChanged<String> onScan;
  final Widget child;

  const WedgeScanner({
    super.key,
    required this.enabled,
    required this.onScan,
    required this.child,
  });

  @override
  State<WedgeScanner> createState() => _WedgeScannerState();
}

class _WedgeScannerState extends State<WedgeScanner> {
  final FocusNode _node = FocusNode(debugLabel: 'wedge', skipTraversal: true);
  final StringBuffer _buf = StringBuffer();

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  /// True when this widget's route is on top — i.e. no dialog (such as the demo
  /// scan input) is open. While a dialog is up we yield focus so its text field
  /// can use the keyboard.
  bool get _isTop => ModalRoute.of(context)?.isCurrent ?? true;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || !_isTop) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      final code = _buf.toString().trim();
      _buf.clear();
      if (code.isNotEmpty) {
        widget.onScan(code);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Accumulate printable characters; ignore control keys.
    final ch = event.character;
    if (ch != null && ch.isNotEmpty && ch.codeUnitAt(0) >= 0x20) {
      _buf.write(ch);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // Keep focus on this node so wedge key events always reach us — but not
    // while a dialog is open, so its text field can take the keyboard.
    if (widget.enabled && _isTop && !_node.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled && _isTop && !_node.hasFocus) {
          _node.requestFocus();
        }
      });
    }
    return Focus(
      focusNode: _node,
      autofocus: widget.enabled,
      onKeyEvent: _onKey,
      child: widget.child,
    );
  }
}
