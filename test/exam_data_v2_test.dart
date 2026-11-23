import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/data/exam_data.dart';
import 'package:yingxiang_tiku_app/data/exam_data_v2.dart';
import 'package:yingxiang_tiku_app/models/paper.dart';
import 'package:yingxiang_tiku_app/models/question.dart';

void main() {
  group('新版试卷数据结构', () {
    test('新版共 5 套试卷', () {
      expect(builtinPapers, hasLength(5));
      expect(builtinPapers.map((Paper p) => p.set).toSet(), <int>{1, 2, 3, 4, 5});
    });

    test('每套试卷 36 题，题型分布正确', () {
      for (final Paper paper in builtinPapers) {
        expect(paper.questions, hasLength(36), reason: '第${paper.set}套题目数');
        int countOf(String type) =>
            paper.questions.where((Question q) => q.type == type).length;
        expect(countOf(QuestionType.single), 10);
        expect(countOf(QuestionType.sharedStem), 6);
        expect(countOf(QuestionType.fillBlank), 10);
        expect(countOf(QuestionType.term), 4);
        expect(countOf(QuestionType.shortAnswer), 4);
        expect(countOf(QuestionType.analysis), 2);
      }
    });

    test('填空题空位数与分值一致（每空 1 分）', () {
      for (final Paper paper in builtinPapers) {
        for (final Question q in paper.questions) {
          if (!q.isFillBlank) continue;
          expect(q.fillBlankAnswers, isNotEmpty, reason: '第${paper.set}套填空');
          expect(
            q.fillBlankAnswers.length,
            q.score.round(),
            reason: '第${paper.set}套填空分值',
          );
        }
      }
    });

    test('填空答案不含空项', () {
      for (final Paper paper in builtinPapers) {
        for (final Question q in paper.questions) {
          if (!q.isFillBlank) continue;
          for (final String blank in q.fillBlankAnswers) {
            expect(blank.trim(), isNotEmpty);
          }
        }
      }
    });

    test('客观/主观统计与题型划分一致', () {
      for (final Paper paper in builtinPapers) {
        expect(paper.objectiveCount, 26, reason: '10单选+6共用+10填空');
        expect(paper.subjectiveCount, 10, reason: '4名解+4简答+2分析');
      }
    });
  });

  group('新旧两版合并', () {
    test('allBuiltinPapers 共 10 套、315 题', () {
      expect(allBuiltinPapers, hasLength(10));
      final int total =
          allBuiltinPapers.fold<int>(0, (int s, Paper p) => s + p.questions.length);
      expect(total, 315);
    });

    test('套次唯一且覆盖 1～10', () {
      final List<int> sets =
          allBuiltinPapers.map((Paper p) => p.set).toList()..sort();
      expect(sets, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('paperOf 跨新旧查找', () {
      expect(paperOf(1).questions, hasLength(36));
      expect(paperOf(10).questions, hasLength(27));
    });

    test('无重复题目（题型 + 题干去重键）', () {
      final Set<String> keys = <String>{};
      int duplicates = 0;
      for (final Paper paper in allBuiltinPapers) {
        for (final Question q in paper.questions) {
          final String key = '${q.type}|${q.stem.trim()}';
          if (!keys.add(key)) duplicates++;
        }
      }
      expect(duplicates, 0);
    });
  });
}
