import 'package:flutter/material.dart';

import '../models/question.dart';
import '../utils/format.dart';
import '../widgets/common.dart';

/// 练习结果页：得分汇总与逐题回顾。
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.answers,
    required this.earned,
  });

  final String title;
  final List<Question> questions;
  final List<String> answers;
  final List<double> earned;

  double get _totalScore =>
      questions.fold<double>(0, (double s, Question q) => s + q.score);

  double get _earnedScore =>
      earned.fold<double>(0, (double s, double e) => s + e);

  int get _objectiveTotal =>
      questions.where((Question q) => q.isObjective).length;

  int get _objectiveCorrect {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].isObjective &&
          answers[i].trim().toUpperCase() ==
              questions[i].answer.trim().toUpperCase()) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('练习结果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _SummaryCard(
            title: title,
            earned: _earnedScore,
            total: _totalScore,
            objectiveCorrect: _objectiveCorrect,
            objectiveTotal: _objectiveTotal,
          ),
          const SizedBox(height: 16),
          const SectionTitle('逐题回顾'),
          for (int i = 0; i < questions.length; i++)
            _ReviewCard(
              index: i,
              question: questions[i],
              userAnswer: answers[i],
              earned: earned[i],
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('关闭'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.earned,
    required this.total,
    required this.objectiveCorrect,
    required this.objectiveTotal,
  });

  final String title;
  final double earned;
  final double total;
  final int objectiveCorrect;
  final int objectiveTotal;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double ratio = total == 0 ? 0 : (earned / total).clamp(0.0, 1.0);
    final String accuracy = objectiveTotal == 0
        ? '—'
        : '${(objectiveCorrect * 100 / objectiveTotal).round()}%';
    return Card(
      elevation: 0,
      color: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${formatScore(earned)} / ${formatScore(total)} 分',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: scheme.onPrimary.withOpacity(0.25),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _MiniStat(
                  label: '客观题',
                  value: '$objectiveCorrect/$objectiveTotal',
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 12),
                _MiniStat(
                  label: '客观正确率',
                  value: accuracy,
                  color: scheme.onPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.userAnswer,
    required this.earned,
  });

  final int index;
  final Question question;
  final String userAnswer;
  final double earned;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool full = earned >= question.score;
    final Color accent =
        full ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                TypeBadge(question.type, compact: true),
                const Spacer(),
                Text(
                  '得 ${formatScore(earned)}/${formatScore(question.score)} 分',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${index + 1}. ${question.stem}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            if (question.isObjective) ...[
              const SizedBox(height: 8),
              Text(
                '我的答案：${userAnswer.isEmpty ? '未作答' : userAnswer}',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              Text(
                '正确答案：${question.answer}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                '我的答案：${userAnswer.isEmpty ? '未作答' : userAnswer}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
