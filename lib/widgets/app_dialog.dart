import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared dialog shell used by all modals in QuickInvent.
/// Provides a consistent gradient header, scrollable body, and sticky footer.
class AppDialog extends StatelessWidget {
  final IconData headerIcon;
  final Color headerColor;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? footer;
  final double maxWidth;
  final double? maxHeight;
  final VoidCallback? onClose;
  final bool canClose;

  const AppDialog({
    super.key,
    required this.headerIcon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.headerColor = AppTheme.primary,
    this.footer,
    this.maxWidth = 520,
    this.maxHeight,
    this.onClose,
    this.canClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight ?? screenH * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gradient Header ───────────────────────────────────
            _AppDialogHeader(
              icon: headerIcon,
              color: headerColor,
              title: title,
              subtitle: subtitle,
              onClose: canClose ? (onClose ?? () => Navigator.pop(context)) : null,
            ),
            // ── Scrollable Body ───────────────────────────────────
            Flexible(child: body),
            // ── Sticky Footer ─────────────────────────────────────
            if (footer != null)
              _AppDialogFooter(child: footer!),
          ],
        ),
      ),
    );
  }
}

class _AppDialogHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  const _AppDialogHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Darken the color slightly for gradient end
    final endColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness - 0.12).clamp(0.0, 1.0),
        )
        .toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppDialogFooter extends StatelessWidget {
  final Widget child;
  const _AppDialogFooter({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: child,
    );
  }
}

// ── Reusable footer button pair ───────────────────────────────────────────────

/// Standard [Cancel] + [Action] footer button row.
class AppDialogFooterButtons extends StatelessWidget {
  final String cancelLabel;
  final String actionLabel;
  final IconData actionIcon;
  final Color? actionColor;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onCancel;
  final VoidCallback? onAction;

  const AppDialogFooterButtons({
    super.key,
    this.cancelLabel = 'Cancelar',
    required this.actionLabel,
    required this.actionIcon,
    this.actionColor,
    this.isLoading = false,
    this.isEnabled = true,
    this.onCancel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = actionColor ?? AppTheme.primary;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : (onCancel ?? () => Navigator.pop(context)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: (isLoading || !isEnabled) ? null : onAction,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              backgroundColor: color,
            ),
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(actionIcon),
            label: Text(
              isLoading ? 'Procesando...' : actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reusable styled input decoration ─────────────────────────────────────────

InputDecoration appInputDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  String? hint,
  String? prefixText,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

// ── Section title ─────────────────────────────────────────────────────────────

class AppDialogSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const AppDialogSectionTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
