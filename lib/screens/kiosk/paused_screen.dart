import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'kiosk_widgets.dart';

/// Shopper-facing screen shown ONLY when the licence tier is `paused`.
///
/// It must read as routine maintenance — NOT an error, and never hint at a
/// licence/billing cause. No buttons, no retry, no codes, no connection state.
class PausedScreen extends StatelessWidget {
  const PausedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final titleSize = (w * 0.04).clamp(28.0, 46.0);
    final subSize = (w * 0.02).clamp(16.0, 22.0);

    return FitScreen(
      maxContentWidth: 720,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Soft rounded tile with a calm clock outline (not a warning icon).
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.line, width: 1.5),
              boxShadow: AppTheme.shadow,
            ),
            child: const Icon(Icons.schedule,
                size: 56, color: AppTheme.inkSoft),
          ),
          const SizedBox(height: 34),
          Text(
            'Price check is taking a short break',
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
              letterSpacingEm: -0.03,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Please ask a team member, or check the price at the till. '
            'Thanks for your patience.',
            textAlign: TextAlign.center,
            style: AppTheme.sans(
              fontSize: subSize,
              color: AppTheme.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          // Small neutral "Back shortly" pill with a faint dot.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.paper2,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.faint,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Back shortly',
                  style: AppTheme.mono(
                    fontSize: 13,
                    color: AppTheme.muted,
                    letterSpacingEm: 0.06,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
