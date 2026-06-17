import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'kiosk_widgets.dart';

/// Idle / attract screen. Invites a scan; tapping the body initiates one
/// (production: automatic on barcode read). Ghost button → Search.
class IdleScreen extends StatelessWidget {
  final bool scanning;
  final VoidCallback onSearch;

  const IdleScreen({
    super.key,
    required this.scanning,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final titleSize = (w * 0.06).clamp(40.0, 66.0);
    final subSize = (w * 0.024).clamp(19.0, 25.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Scanning is via the hardware wedge; a tap offers manual entry.
      onTap: scanning ? null : onSearch,
      child: FitScreen(
        maxContentWidth: 640,
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScanTarget(scanning: scanning),
                const SizedBox(height: 30),
                Text(
                  scanning ? 'Reading barcode…' : 'Scan your item',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                    letterSpacingEm: -0.03,
                    height: 1.02,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scanning
                      ? 'Hold steady'
                      : 'Hold the barcode up to the scanner to see the price',
                  textAlign: TextAlign.center,
                  style: AppTheme.sans(
                    fontSize: subSize,
                    color: AppTheme.inkSoft,
                  ),
                ),
                if (!scanning) ...[
                  const SizedBox(height: 34),
                  KButton(
                    label: 'Enter a code instead',
                    icon: Icons.search,
                    kind: KButtonKind.ghost,
                    xl: true,
                    onPressed: onSearch,
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
