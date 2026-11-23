import 'package:flutter/material.dart';

import '../models/question.dart';

/// 将选项序号转换为字母（0→A）。
String optionLetter(int index) => String.fromCharCode(65 + index);

/// 题型对应的强调色。
Color typeColor(String type) {
  switch (type) {
    case QuestionType.single:
      return const Color(0xFF2196F3);
    case QuestionType.sharedStem:
      return const Color(0xFF9C27B0);
    case QuestionType.term:
      return const Color(0xFF009688);
    case QuestionType.shortAnswer:
      return const Color(0xFFFF9800);
    case QuestionType.analysis:
      return const Color(0xFFF44336);
    default:
      return Colors.grey;
  }
}

/// 题型对应的图标。
IconData typeIcon(String type) {
  switch (type) {
    case QuestionType.single:
      return Icons.check_circle_outline;
    case QuestionType.sharedStem:
      return Icons.groups_outlined;
    case QuestionType.term:
      return Icons.menu_book_outlined;
    case QuestionType.shortAnswer:
      return Icons.edit_note_outlined;
    case QuestionType.analysis:
      return Icons.fact_check_outlined;
    default:
      return Icons.help_outline;
  }
}

/// 题型标签。
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key, this.compact = false});

  final String type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = typeColor(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(typeIcon(type), size: compact ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空状态视图。
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final Color hint = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: hint.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: hint, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分区标题。
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
