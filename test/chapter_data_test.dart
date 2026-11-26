import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/data/chapter_data.dart';
import 'package:yingxiang_tiku_app/models/question.dart';
import 'package:yingxiang_tiku_app/utils/multi_choice_grader.dart';

/// 分章节题库（`lib/data/chapter_data.dart`）数据完整性验证。
void main() {
  group('ChapterQuestionBank 章节结构', () {
    test('共 10 章且章节名唯一', () {
      expect(ChapterQuestionBank.allChapters, hasLength(10));
      expect(
        ChapterQuestionBank.allChapters.toSet(),
        hasLength(10),
      );
    });

    test('章节名映射与顺序列表完全一致', () {
      expect(
        ChapterQuestionBank.chapterQuestions.keys.toSet(),
        ChapterQuestionBank.allChapters.toSet(),
      );
    });

    test('每章均包含题目', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        expect(
          ChapterQuestionBank.countOf(chapter),
          greaterThan(0),
          reason: '$chapter 应有题目',
        );
      }
    });

    test('总题数等于各章题数之和', () {
      int sum = 0;
      for (final String chapter in ChapterQuestionBank.allChapters) {
        sum += ChapterQuestionBank.countOf(chapter);
      }
      expect(ChapterQuestionBank.totalCount, sum);
      expect(ChapterQuestionBank.totalCount, greaterThan(0));
    });
  });

  group('每章题目字段完整性', () {
    test('每题 chapter 字段与其所属章节一致', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        final List<Question> questions =
            ChapterQuestionBank.chapterQuestions[chapter]!;
        expect(
          questions.every((Question q) => q.chapter == chapter),
          isTrue,
          reason: '$chapter 中存在 chapter 字段不一致的题',
        );
      }
    });

    test('每题题干非空、题型合法', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          expect(q.stem.trim(), isNotEmpty, reason: '$chapter 存在空题干');
          expect(QuestionType.all, contains(q.type), reason: '$chapter 存在非法题型 ${q.type}');
        }
      }
    });

    test('客观题（单选/多选）选项与答案非空', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          if (q.type == QuestionType.single || q.type == QuestionType.multiChoice) {
            expect(q.options, isNotEmpty, reason: '$chapter 客观题缺少选项：${q.stem}');
            expect(q.answer.trim(), isNotEmpty, reason: '$chapter 客观题缺少答案：${q.stem}');
          }
        }
      }
    });

    test('主观题（名词解释/简答）参考答案非空', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          if (q.type == QuestionType.term || q.type == QuestionType.shortAnswer) {
            expect(q.answer.trim(), isNotEmpty, reason: '$chapter 主观题缺少参考答案：${q.stem}');
          }
        }
      }
    });

    test('多选题答案为合法字母集合', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          if (q.type == QuestionType.multiChoice) {
            expect(
              MultiChoiceGrader.parseLetters(q.answer),
              isNotEmpty,
              reason: '$chapter 多选题答案非法：${q.answer}',
            );
          }
        }
      }
    });

    test('单选题答案为单个字母且落在选项范围内（含 6/7 选项题）', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          if (q.type == QuestionType.single) {
            final String a = q.answer.trim().toUpperCase();
            expect(a, hasLength(1), reason: '$chapter 单选答案应为单个字母：${q.answer}');
            expect(
              RegExp(r'[A-Z]').hasMatch(a),
              isTrue,
              reason: '$chapter 单选答案非法：${q.answer}',
            );
            if (a.length == 1 && RegExp(r'[A-Z]').hasMatch(a)) {
              final int idx = a.codeUnitAt(0) - 65;
              expect(
                idx,
                lessThan(q.options.length),
                reason: '$chapter 单选答案超出选项范围：${q.answer} / ${q.options.length} 个选项',
              );
            }
          }
        }
      }
    });

    test('多选题答案字母均落在选项范围内', () {
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          if (q.type == QuestionType.multiChoice) {
            final Set<String> letters = MultiChoiceGrader.parseLetters(q.answer);
            for (final String letter in letters) {
              final int idx = letter.codeUnitAt(0) - 65;
              expect(
                idx,
                lessThan(q.options.length),
                reason: '$chapter 多选题答案超出选项范围：${q.answer} / ${q.options.length} 个选项',
              );
            }
          }
        }
      }
    });
  });

  group('分章节题库题型数量统计', () {
    test('总题数 806，题型分布符合提取结果', () {
      int single = 0;
      int multiChoice = 0;
      int term = 0;
      int shortAnswer = 0;
      for (final String chapter in ChapterQuestionBank.allChapters) {
        for (final Question q in ChapterQuestionBank.chapterQuestions[chapter]!) {
          final String t = q.type;
          if (t == QuestionType.single) {
            single++;
          } else if (t == QuestionType.multiChoice) {
            multiChoice++;
          } else if (t == QuestionType.term) {
            term++;
          } else if (t == QuestionType.shortAnswer) {
            shortAnswer++;
          }
        }
      }
      expect(ChapterQuestionBank.totalCount, 806);
      expect(single, 440);
      expect(multiChoice, 187);
      expect(term, 85);
      expect(shortAnswer, 94);
      expect(single + multiChoice + term + shortAnswer, 806);
    });
  });
}
