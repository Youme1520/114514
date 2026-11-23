import 'package:flutter/material.dart';

import '../models/paper.dart';
import '../models/question.dart';
import '../models/study_progress.dart';
import '../widgets/common.dart';
import 'practice_screen.dart';

/// 试卷详情：题型分布与整套练习入口。
class PaperDetailScreen extends StatelessWidget {
  const PaperDetailScreen({super.key, required this.paper});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> distribution = <String, int>{};
    for (final Question q in paper.questions) {
      distribution[q.type] = (distribution[q.type] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(title: Text('第${paper.set}套试卷')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    paper.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '考查范围：${paper.scope}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _StatRow(label: '题目总数', value: '${paper.questions.length} 题'),
                  _StatRow(label: '客观题', value: '${paper.objectiveCount} 题'),
                  _StatRow(label: '主观题', value: '${paper.subjectiveCount} 题'),
                  _StatRow(label: '试卷满分', value: '${paper.totalScore} 分'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('题型分布'),
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  for (final String type in QuestionType.all)
                    if (distribution.containsKey(type))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            TypeBadge(type),
                            const Spacer(),
                            Text(
                              '${distribution[type]} 题',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeScreen(
                    title: '第${paper.set}套 · 整套练习',
                    questions: paper.questions,
                    resumeKind: ProgressKind.paper,
                    resumeIdentifier: '${paper.set}',
                  ),
                ),
              ),
              child: const Text('整套练习'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
