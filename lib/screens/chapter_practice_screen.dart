import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/chapter_data.dart';
import '../models/study_progress.dart';
import '../providers/study_provider.dart';
import 'practice_screen.dart';

/// 分章节刷题：列出十章的题数与入口，点击后进入对应章节练习。
class ChapterPracticeScreen extends StatelessWidget {
  const ChapterPracticeScreen({super.key});

  /// 各章节主题色（按顺序轮换，暗色模式下依旧清晰）。
  static const List<Color> _chapterColors = <Color>[
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFF8E24AA),
    Color(0xFF43A047),
    Color(0xFF00897B),
    Color(0xFFD81B60),
    Color(0xFF3949AB),
    Color(0xFFF4511E),
    Color(0xFF00695C),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分章节刷题')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '共 ${ChapterQuestionBank.totalCount} 题 · 十章习题精练',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (int i = 0; i < ChapterQuestionBank.allChapters.length; i++)
            _ChapterCard(
              chapter: ChapterQuestionBank.allChapters[i],
              count: ChapterQuestionBank.countOf(
                ChapterQuestionBank.allChapters[i],
              ),
              color: _chapterColors[i % _chapterColors.length],
            ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.count,
    required this.color,
  });

  final String chapter;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final VoidCallback? onStart = count == 0
        ? null
        : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PracticeScreen(
                  title: '$chapter · 分章节练习',
                  questions: context
                      .read<StudyProvider>()
                      .questionsByChapter(chapter),
                  resumeKind: ProgressKind.chapter,
                  resumeIdentifier: chapter,
                ),
              ),
            );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      chapter,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '共 $count 题',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('开始'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
