import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Scales its child down (never up) so a whole screen always fits the available
/// viewport — no scrolling, no overflow — at any landscape size from a 320px-tall
/// phone up to a desktop window. On large screens the content stays at natural
/// size (BoxFit.scaleDown caps at 1.0); on small ones it shrinks uniformly,
/// which proportionally reduces spacing, padding, icons, and type together.
///
/// The child is laid out at a fixed [contentWidth] (derived from the viewport,
/// capped by [maxContentWidth]) so text wrapping is stable before scaling.
class FitScreen extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxContentWidth;
  final Alignment alignment;
  const FitScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.maxContentWidth = 1180,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final avail = c.maxWidth - padding.horizontal;
        final width = avail.clamp(0.0, maxContentWidth);
        return Padding(
          padding: padding,
          child: Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(width: width, child: child),
            ),
          ),
        );
      },
    );
  }
}

/// Button variants from the handoff: primary (dark), scan (accent), ghost
/// (surface + border). `xl` raises the min-height / font for primary actions.
enum KButtonKind { primary, scan, ghost }

class KButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool iconTrailing;
  final KButtonKind kind;
  final bool xl;
  final bool enabled;
  final VoidCallback? onPressed;

  const KButton({
    super.key,
    required this.label,
    this.icon,
    this.iconTrailing = false,
    this.kind = KButtonKind.primary,
    this.xl = false,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final on = enabled && onPressed != null;
    late Color bg, fg;
    Border? border;
    List<BoxShadow>? shadow;
    switch (kind) {
      case KButtonKind.primary:
        bg = AppTheme.ink;
        fg = AppTheme.paper;
        shadow = AppTheme.shadow;
        break;
      case KButtonKind.scan:
        bg = AppTheme.accent;
        fg = Colors.white;
        shadow = const [
          BoxShadow(
            color: Color(0x4D1F7A52),
            blurRadius: 30,
            spreadRadius: -14,
            offset: Offset(0, 12),
          ),
        ];
        break;
      case KButtonKind.ghost:
        bg = AppTheme.surface;
        fg = AppTheme.ink;
        border = Border.all(color: AppTheme.line, width: 1.5);
        break;
    }

    final iconWidget = icon == null
        ? null
        : Icon(icon, size: xl ? 28 : 26, color: fg);
    final text = Text(
      label,
      style: AppTheme.sans(
        fontSize: xl ? 21 : 19,
        fontWeight: FontWeight.w600,
        color: fg,
        letterSpacingEm: -0.01,
      ),
    );
    final children = <Widget>[
      if (iconWidget != null && !iconTrailing) ...[
        iconWidget,
        const SizedBox(width: 12),
      ],
      Flexible(child: text),
      if (iconWidget != null && iconTrailing) ...[
        const SizedBox(width: 12),
        iconWidget,
      ],
    ];

    return Opacity(
      opacity: on ? 1 : (kind == KButtonKind.primary ? 0.32 : 0.5),
      child: _Pressable(
        onPressed: on ? onPressed : null,
        child: Container(
          constraints: BoxConstraints(minHeight: xl ? 76 : 64),
          padding: EdgeInsets.symmetric(horizontal: xl ? 34 : 28),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: border,
            boxShadow: on ? shadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Scale-down-on-press wrapper (matches `.btn:active { transform: scale(.975) }`).
class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  const _Pressable({required this.child, this.onPressed});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onPressed == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

/// Simple barcode glyph (vertical bars) for the scan target and code line.
class BarcodeGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const BarcodeGlyph({super.key, this.size = 94, this.color = AppTheme.ink});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.62,
      child: CustomPaint(painter: _BarcodePainter(color)),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final Color color;
  _BarcodePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    // Bar pattern (x position fraction, stroke width fraction).
    const bars = <List<double>>[
      [0.04, 0.5],
      [0.14, 0.5],
      [0.24, 0.5],
      [0.40, 0.5],
      [0.56, 0.5],
      [0.72, 0.5],
      [0.88, 0.5],
    ];
    for (final b in bars) {
      p.strokeWidth = size.width * 0.045;
      final x = size.width * b[0] + size.width * 0.05;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) => old.color != color;
}

/// The animated scan-target card on the idle screen: corner brackets, barcode
/// glyph (idle pulse), and an accent scan-line sweep while scanning.
class ScanTarget extends StatefulWidget {
  final bool scanning;
  const ScanTarget({super.key, required this.scanning});

  @override
  State<ScanTarget> createState() => _ScanTargetState();
}

class _ScanTargetState extends State<ScanTarget>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final side = (w * 0.30).clamp(220.0, 320.0);
    final height = side / 1.25;
    final scanning = widget.scanning;
    return Container(
      width: side,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: scanning
            ? AppTheme.shadowLg
            : AppTheme.shadow,
        border: scanning
            ? Border.all(color: AppTheme.accentLine, width: 4)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ..._corners(),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Opacity(
              opacity: 0.55 + 0.35 * _pulse.value,
              child: const BarcodeGlyph(size: 94, color: AppTheme.ink),
            ),
          ),
          if (scanning)
            AnimatedBuilder(
              animation: _sweep,
              builder: (_, _) {
                final dy = (height / 2 - 14) * (2 * _sweep.value - 1);
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Container(
                    height: 3,
                    width: side - 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x001F7A52),
                          AppTheme.accent,
                          Color(0x001F7A52),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _corners() {
    const arm = 34.0;
    const inset = 20.0;
    const t = 3.5;
    Widget corner(Alignment a, {required bool top, required bool left}) {
      return Positioned(
        top: top ? inset : null,
        bottom: top ? null : inset,
        left: left ? inset : null,
        right: left ? null : inset,
        child: SizedBox(
          width: arm,
          height: arm,
          child: CustomPaint(
            painter: _CornerPainter(top: top, left: left, thickness: t),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft, top: true, left: true),
      corner(Alignment.topRight, top: true, left: false),
      corner(Alignment.bottomLeft, top: false, left: true),
      corner(Alignment.bottomRight, top: false, left: false),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  final double thickness;
  _CornerPainter({required this.top, required this.left, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.accent
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final yEdge = top ? thickness / 2 : size.height - thickness / 2;
    final xEdge = left ? thickness / 2 : size.width - thickness / 2;
    // Horizontal arm
    canvas.drawLine(Offset(0, yEdge), Offset(size.width, yEdge), p);
    // Vertical arm
    canvas.drawLine(Offset(xEdge, 0), Offset(xEdge, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => false;
}
