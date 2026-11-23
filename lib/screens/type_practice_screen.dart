import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

/// 分题型刷题：选择题型后进入练习。
class TypePracticeScreen extends StatelessWidget {
  const TypePracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StudyProvider study = context.watch<StudyProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('分题型刷题')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final String type in QuestionType.all)
            _TypeCard(
              type: type,
              count: study.questionsByType(type).length,
            ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type, required this.count});

  final String type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Color color = typeColor(type);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon(type), color: color),
        ),
        title: Text(
          type,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '共 $count 题',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: count == 0
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PracticeScreen(
                        title: '$type · 专项练习',
                        questions: context
                            .read<StudyProvider>()
                            .questionsByType(type),
                      ),
                    ),
                  ),
          child: const Text('开始'),
        ),
      ),
    );
  }
}
