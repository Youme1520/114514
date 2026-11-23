import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/knowledge_card.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';
import 'card_study_screen.dart';

/// 背诵页：章节列表，进入翻卡背诵。
class MemorizeScreen extends StatelessWidget {
  const MemorizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StudyProvider study = context.watch<StudyProvider>();
    // 建立卡片 -> 全局索引映射（卡片引用与 allCards 一致）。
    final Map<KnowledgeCard, int> globalIndex = <KnowledgeCard, int>{};
    for (int i = 0; i < study.allCards.length; i++) {
      globalIndex[study.allCards[i]] = i;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('背诵')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final KnowledgeChapter chapter in study.chapters)
            _ChapterCard(
              chapter: chapter,
              mastered: chapter.cards
                  .where((KnowledgeCard c) =>
                      study.memorizedIndexes.contains(globalIndex[c]))
                  .length,
            ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.mastered});

  final KnowledgeChapter chapter;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress = chapter.cards.isEmpty
        ? 0
        : mastered / chapter.cards.length;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CardStudyScreen(chapter: chapter),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.style_outlined, color: scheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          chapter.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${chapter.cards.length} 张卡片 · 已掌握 $mastered',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
