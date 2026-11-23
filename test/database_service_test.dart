import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yingxiang_tiku_app/models/question.dart';
import 'package:yingxiang_tiku_app/services/database_service.dart';

void main() {
  sqfliteFfiInit();

  setUp(() {
    DatabaseService.overrideForTest(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await DatabaseService.instance.close();
  });

  group('导入题目 CRUD', () {
    test('批量插入并查询（含 JSON 序列化往返）', () async {
      final Question q = Question(
        paperSet: 0,
        type: QuestionType.single,
        chapter: '基础',
        stem: '测试题干',
        options: const <String>['A', 'B'],
        answer: 'B',
        analysis: '解析',
        score: 2,
      );

      final int inserted =
          await DatabaseService.instance.insertImportedQuestions(<Question>[q]);
      expect(inserted, 1);

      final List<Question> list =
          await DatabaseService.instance.getImportedQuestions();
      expect(list, hasLength(1));
      final Question loaded = list.first;
      expect(loaded.id, isNotNull);
      expect(loaded.stem, '测试题干');
      expect(loaded.options, <String>['A', 'B']);
      expect(loaded.answer, 'B');
      expect(loaded.source, QuestionSource.imported);
    });

    test('空列表插入返回 0', () async {
      expect(
        await DatabaseService.instance.insertImportedQuestions(<Question>[]),
        0,
      );
    });

    test('删除单条导入题目', () async {
      await DatabaseService.instance.insertImportedQuestions(<Question>[
        Question(paperSet: 0, type: QuestionType.single, stem: 'a', answer: 'A'),
      ]);
      final List<Question> list =
          await DatabaseService.instance.getImportedQuestions();
      expect(list, hasLength(1));

      await DatabaseService.instance.deleteImportedQuestion(list.first.id!);
      expect(
        await DatabaseService.instance.getImportedQuestions(),
        isEmpty,
      );
    });

    test('清空全部导入题目', () async {
      await DatabaseService.instance.insertImportedQuestions(<Question>[
        Question(paperSet: 0, type: QuestionType.single, stem: 'a', answer: 'A'),
        Question(paperSet: 0, type: QuestionType.term, stem: 'b', answer: 'x'),
      ]);
      expect(
        await DatabaseService.instance.getImportedQuestions(),
        hasLength(2),
      );

      await DatabaseService.instance.clearImportedQuestions();
      expect(
        await DatabaseService.instance.getImportedQuestions(),
        isEmpty,
      );
    });
  });

  group('答题记录', () {
    test('插入并倒序查询', () async {
      await DatabaseService.instance.insertAnswerRecord(
        stem: '题干',
        userAnswer: 'A',
        correct: true,
      );
      await DatabaseService.instance.insertAnswerRecord(
        stem: '题干',
        userAnswer: 'B',
        correct: false,
      );

      final List<Map<String, dynamic>> records =
          await DatabaseService.instance.getAnswerRecords();
      expect(records, hasLength(2));
      // 按 id DESC 排序，最新一条在前。
      expect(records.first['is_correct'], 0);
      expect(records.last['is_correct'], 1);
    });
  });
}
