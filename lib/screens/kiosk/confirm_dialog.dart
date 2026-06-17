import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// Canonical confirmation dialog (ported from StockRoom): icon disc, title,
/// message, an optional consequence panel ([info] rows) and two equal buttons.
/// [destructive] renders the confirm button red.
class ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final List<(IconData, String)> info;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;

  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.message,
    this.info = const [],
    this.cancelLabel = 'Cancel',
    required this.confirmLabel,
    this.destructive = false,
  });

  /// Shows the dialog; returns true if confirmed.
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    List<(IconData, String)> info = const [],
    String cancelLabel = 'Cancel',
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        icon: icon,
        iconBg: iconBg,
        iconColor: iconColor,
        title: title,
        message: message,
        info: info,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return r == true;
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = destructive ? AppTheme.danger : AppTheme.accent;
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.sans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacingEm: -0.01),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.sans(
                    fontSize: 14, color: AppTheme.inkSoft, height: 1.5),
              ),
              if (info.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.paper2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    children: [
                      for (final (i, (ic, txt)) in info.indexed) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(ic, size: 16, color: AppTheme.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(txt,
                                  style: AppTheme.mono(
                                      fontSize: 12, color: AppTheme.inkSoft)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _Btn(
                      label: cancelLabel,
                      bg: AppTheme.surface,
                      fg: AppTheme.ink,
                      border: true,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Btn(
                      label: confirmLabel,
                      bg: confirmColor,
                      fg: Colors.white,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final bool border;
  final VoidCallback onTap;
  const _Btn({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
    this.border = false,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: border
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.line, width: 1.5),
                )
              : null,
          child: Text(label,
              style: AppTheme.sans(
                  fontSize: 16, fontWeight: FontWeight.w600, color: fg)),
        ),
      ),
    );
  }
}
