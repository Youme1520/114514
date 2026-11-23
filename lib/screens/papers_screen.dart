import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/paper.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';
import 'paper_detail_screen.dart';
import 'type_practice_screen.dart';

/// 刷题页：内置试卷列表 + 分题型刷题入口。
class PapersScreen extends StatelessWidget {
  const PapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StudyProvider study = context.watch<StudyProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('刷题')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(
                  Icons.category_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  '分题型刷题',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('单选 / 共用题干 / 名词解释 / 简答 / 分析'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TypePracticeScreen(),
                  ),
                ),
              ),
            ),
          ),
          const SectionTitle('内置试卷（5套）'),
          for (final Paper paper in study.papers) _PaperCard(paper: paper),
        ],
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.paper});

  final Paper paper;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${paper.set}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        paper.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        paper.scope,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _InfoChip(text: '${paper.questions.length} 题'),
                const SizedBox(width: 8),
                _InfoChip(text: '客观 ${paper.objectiveCount}'),
                const SizedBox(width: 8),
                _InfoChip(text: '主观 ${paper.subjectiveCount}'),
                const SizedBox(width: 8),
                _InfoChip(text: '满分 ${paper.totalScore}'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PaperDetailScreen(paper: paper),
                  ),
                ),
                child: const Text('开始练习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
