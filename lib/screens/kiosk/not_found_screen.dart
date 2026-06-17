import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import 'kiosk_widgets.dart';

/// Recover from an unrecognised code. Names the failed query in monospace.
class NotFoundScreen extends StatelessWidget {
  final String query;
  final VoidCallback onScan;
  final VoidCallback onRetry;

  const NotFoundScreen({
    super.key,
    required this.query,
    required this.onScan,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final titleSize = (w * 0.05).clamp(34.0, 48.0);

    return FitScreen(
      maxContentWidth: 560,
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.line, width: 1.5),
                ),
                child: const Icon(Icons.search_off, size: 56, color: AppTheme.muted),
              ),
              const SizedBox(height: 26),
              Text(
                'No match found',
                textAlign: TextAlign.center,
                style: AppTheme.sans(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacingEm: -0.03,
                ),
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  style: AppTheme.sans(
                    fontSize: 21,
                    color: AppTheme.inkSoft,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'We couldn’t find '),
                    TextSpan(
                      text: '“$query”',
                      style: AppTheme.mono(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.ink,
                      ),
                    ),
                    const TextSpan(
                      text: '. Check the code and try again, '
                          'or ask a team member for help.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  KButton(
                    label: 'Scan an item',
                    icon: Icons.qr_code_scanner,
                    kind: KButtonKind.scan,
                    xl: true,
                    onPressed: onScan,
                  ),
                  KButton(
                    label: 'Try again',
                    icon: Icons.refresh,
                    kind: KButtonKind.ghost,
                    xl: true,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
