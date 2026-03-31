import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final bool isPrimary;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon ?? Icons.arrow_forward, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}
