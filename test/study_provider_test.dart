import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/data/chapter_data.dart';
import 'package:yingxiang_tiku_app/models/question.dart';
import 'package:yingxiang_tiku_app/models/study_progress.dart';
import 'package:yingxiang_tiku_app/providers/study_provider.dart';
import 'package:yingxiang_tiku_app/services/database_service.dart';
import 'package:yingxiang_tiku_app/services/settings_service.dart';

/// 验证 StudyProvider 的内置题库合并、题型筛选与断点续传重建逻辑。
///
/// 这些方法均为纯内存计算，不依赖数据库初始化，因此无需 sqflite_common_ffi。
void main() {
  StudyProvider buildProvider() => StudyProvider(
        db: DatabaseService.instance,
        settings: SettingsService(),
      );

  group('内置题库合并', () {
    test('内置题总数为 315（新版 180 + 旧版 135）', () {
      expect(buildProvider().totalBuiltinQuestions, 315);
      expect(buildProvider().builtinQuestions, hasLength(315));
    });

    test('papers 共 10 套且套次唯一覆盖 1～10', () {
      final List<int> sets =
          buildProvider().papers.map((p) => p.set).toList()..sort();
      expect(sets, <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('paperBySet 跨新旧两版查找', () {
      final StudyProvider provider = buildProvider();
      expect(provider.paperBySet(1)?.questions, hasLength(36));
      expect(provider.paperBySet(6)?.questions, hasLength(27));
      expect(provider.paperBySet(10)?.questions, hasLength(27));
      expect(provider.paperBySet(11), isNull);
    });
  });

  group('questionsByType 纳入填空题', () {
    test('填空题共 50 题（新版内置）', () {
      expect(
        buildProvider().questionsByType(QuestionType.fillBlank),
        hasLength(50),
      );
    });

    test('单选 540 题（内置 100 + 分章节 440）、共用题干 60 题', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.single), hasLength(540));
      expect(provider.questionsByType(QuestionType.sharedStem), hasLength(60));
    });

    test('筛选结果全部为指定题型', () {
      final List<Question> questions =
          buildProvider().questionsByType(QuestionType.fillBlank);
      expect(questions.every((Question q) => q.isFillBlank), isTrue);
    });
  });

  group('questionsByType 纳入分章节题库', () {
    test('多选 187 题（分章节题库 X 型题）', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.multiChoice), hasLength(187));
    });

    test('名词解释 130 题（内置 45 + 分章节 85）', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.term), hasLength(130));
    });

    test('简答 139 题（内置 45 + 分章节 94）', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.shortAnswer), hasLength(139));
    });

    test('分析题 15 题（仅内置，分章节题库无此类题型）', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.analysis), hasLength(15));
    });

    test('各题型之和等于题库总数 1121', () {
      final StudyProvider provider = buildProvider();
      int sum = 0;
      for (final String type in QuestionType.all) {
        sum += provider.questionsByType(type).length;
      }
      expect(sum, 1121);
    });
  });

  group('resumeQuestionsFor 断点续传重建', () {
    test('paper 套次恢复整套题', () {
      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.paper,
        title: '第1套 · 整套练习',
        identifier: '1',
        totalCount: 36,
      );
      expect(buildProvider().resumeQuestionsFor(progress), hasLength(36));
    });

    test('type 题型恢复分题型题', () {
      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.type,
        title: '填空 · 专项练习',
        identifier: QuestionType.fillBlank,
        totalCount: 50,
      );
      expect(buildProvider().resumeQuestionsFor(progress), hasLength(50));
    });

    test('无效套次返回空列表', () {
      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.paper,
        title: 'x',
        identifier: '99',
        totalCount: 10,
      );
      expect(buildProvider().resumeQuestionsFor(progress), isEmpty);
    });

    test('未知进度种类返回空列表', () {
      final StudyProgress progress = StudyProgress(
        kind: 'unknown',
        title: 'x',
        identifier: '1',
        totalCount: 10,
      );
      expect(buildProvider().resumeQuestionsFor(progress), isEmpty);
    });
  });

  group('分章节题库访问', () {
    test('chapterNames 共 10 章且与题库映射一致', () {
      final StudyProvider provider = buildProvider();
      expect(provider.chapterNames, hasLength(10));
      expect(
        provider.chapterQuestions.keys.toSet(),
        provider.chapterNames.toSet(),
      );
    });

    test('totalChapterQuestions 等于各章题数之和', () {
      final StudyProvider provider = buildProvider();
      int sum = 0;
      for (final String chapter in provider.chapterNames) {
        sum += provider.chapterQuestionCount(chapter);
      }
      expect(provider.totalChapterQuestions, sum);
      expect(provider.totalChapterQuestions, greaterThan(0));
    });

    test('questionsByChapter 返回指定章节全部题目', () {
      final StudyProvider provider = buildProvider();
      final List<Question> questions =
          provider.questionsByChapter(ChapterQuestionBank.ch1);
      expect(questions, hasLength(ChapterQuestionBank.countOf(ChapterQuestionBank.ch1)));
      expect(
        questions.every((Question q) => q.chapter == ChapterQuestionBank.ch1),
        isTrue,
      );
    });

    test('resumeQuestionsFor 支持 chapter 进度', () {
      final StudyProvider provider = buildProvider();
      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.chapter,
        title: '${ChapterQuestionBank.ch1} · 分章节练习',
        identifier: ChapterQuestionBank.ch1,
        totalCount: ChapterQuestionBank.countOf(ChapterQuestionBank.ch1),
      );
      expect(
        provider.resumeQuestionsFor(progress),
        hasLength(ChapterQuestionBank.countOf(ChapterQuestionBank.ch1)),
      );
    });

    test('无效章节返回空列表', () {
      expect(buildProvider().questionsByChapter('不存在的章节'), isEmpty);
    });

    test('totalQuestions 纳入分章节题库（内置 315 + 分章节 806）', () {
      final StudyProvider provider = buildProvider();
      expect(provider.totalBuiltinQuestions, 315);
      expect(provider.totalChapterQuestions, 806);
      expect(provider.totalQuestions, 315 + 806);
    });
  });
}
