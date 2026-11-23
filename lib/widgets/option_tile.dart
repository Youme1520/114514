import 'package:flutter/material.dart';

import 'common.dart';

/// 客观题选项卡片。
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.index,
    required this.text,
    required this.isSelected,
    this.isCorrect = false,
    this.showResult = false,
    this.onTap,
  });

  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color background = scheme.surface;
    Color border = scheme.outline;
    Color letterBg = scheme.surfaceVariant;
    Color letterFg = scheme.onSurface;

    if (showResult) {
      if (isCorrect) {
        background = isDark ? const Color(0xFF1B3B2E) : const Color(0xFFE6F4EA);
        border = const Color(0xFF4CAF50);
        letterBg = const Color(0xFF4CAF50);
        letterFg = Colors.white;
      } else if (isSelected && !isCorrect) {
        background = isDark ? const Color(0xFF462323) : const Color(0xFFFDEAEA);
        border = const Color(0xFFE53935);
        letterBg = const Color(0xFFE53935);
        letterFg = Colors.white;
      }
    } else if (isSelected) {
      background = scheme.primary.withOpacity(0.12);
      border = scheme.primary;
      letterBg = scheme.primary;
      letterFg = scheme.onPrimary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 16,
              backgroundColor: letterBg,
              child: Text(
                optionLetter(index),
                style: TextStyle(
                  color: letterFg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
            if (showResult && isCorrect)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20)
            else if (showResult && isSelected && !isCorrect)
              const Icon(Icons.cancel, color: Color(0xFFE53935), size: 20),
          ],
        ),
      ),
    );
  }
}
