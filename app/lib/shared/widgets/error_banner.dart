import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable non-alarming error / warning banner matching app styling.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1328),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFF4C1D95).withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.0, color: const Color(0xFFC084FC)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.0,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8.0),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                minimumSize: const Size(48.0, 36.0),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentCyan,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
