import 'package:flutter_test/flutter_test.dart';

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

    test('单选 100 题、共用题干 60 题', () {
      final StudyProvider provider = buildProvider();
      expect(provider.questionsByType(QuestionType.single), hasLength(100));
      expect(provider.questionsByType(QuestionType.sharedStem), hasLength(60));
    });

    test('筛选结果全部为指定题型', () {
      final List<Question> questions =
          buildProvider().questionsByType(QuestionType.fillBlank);
      expect(questions.every((Question q) => q.isFillBlank), isTrue);
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
}
