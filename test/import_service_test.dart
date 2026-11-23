import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/models/question.dart';
import 'package:yingxiang_tiku_app/services/import_service.dart';

void main() {
  group('JSON 解析', () {
    test('根节点为数组', () {
      const String json = '''
[
  {
    "type": "单选",
    "stem": "水的CT值是多少？",
    "options": ["A. -1000", "B. 0"],
    "answer": "B",
    "analysis": "水为0 HU。",
    "chapter": "基础",
    "score": 2
  }
]
''';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      final Question q = r.questions.first;
      expect(q.type, '单选');
      expect(q.stem, '水的CT值是多少？');
      expect(q.options, <String>['A. -1000', 'B. 0']);
      expect(q.answer, 'B');
      expect(q.score, 2.0);
    });

    test('根节点为包含 questions 字段的对象', () {
      const String json = '''
{"questions": [
  {"type": "名词解释", "stem": "CT值", "answer": "定义"}
]}
''';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      expect(r.questions.first.stem, 'CT值');
    });

    test('根节点为包含 data 字段的对象', () {
      const String json = '''
{"data": [
  {"type": "简答", "stem": "简述", "answer": "要点"}
]}
''';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
    });

    test('根节点为单道题对象', () {
      const String json = '{"type": "单选", "stem": "单题题干", "answer": "A"}';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      expect(r.questions.first.stem, '单题题干');
    });

    test('非法 JSON 返回错误而不抛异常', () {
      final ImportResult r = ImportService().parseText('not json{', 'q.json');
      expect(r.hasError, isTrue);
      expect(r.error, isNotNull);
      expect(r.questions, isEmpty);
    });

    test('数组中混入非对象元素时跳过', () {
      const String json = '''
[
  {"type": "单选", "stem": "有效题", "answer": "A"},
  123,
  "bad"
]
''';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      expect(r.skipped, 2);
    });

    test('空题干被跳过', () {
      const String json = '''
[
  {"type": "单选", "stem": "   ", "answer": "A"},
  {"type": "单选", "stem": "有效", "answer": "B"}
]
''';
      final ImportResult r = ImportService().parseText(json, 'q.json');
      expect(r.questions, hasLength(1));
      expect(r.skipped, 1);
    });
  });

  group('CSV 解析', () {
    test('英文字段表头 + 竖线分隔选项', () {
      const String csv = 'type,stem,options,answer,analysis,chapter,score\n'
          '单选,水的CT值是多少？,-1000|0|100|1000,B,水为0 HU。,基础,2\n';
      final ImportResult r = ImportService().parseText(csv, 'q.csv');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      final Question q = r.questions.first;
      expect(q.type, '单选');
      expect(q.stem, '水的CT值是多少？');
      expect(q.options, <String>['-1000', '0', '100', '1000']);
      expect(q.answer, 'B');
      expect(q.analysis, '水为0 HU。');
      expect(q.chapter, '基础');
      expect(q.score, 2.0);
    });

    test('中文字段表头', () {
      const String csv = '题型,题干,选项,答案,解析,章节,分值\n'
          '名词解释,CT值,,CT值是像素对X线吸收系数的换算值。,要点,基础,3\n';
      final ImportResult r = ImportService().parseText(csv, 'q.csv');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      final Question q = r.questions.first;
      expect(q.type, '名词解释');
      expect(q.stem, 'CT值');
      expect(q.options, isEmpty);
      expect(q.answer, 'CT值是像素对X线吸收系数的换算值。');
      expect(q.chapter, '基础');
      expect(q.score, 3.0);
    });

    test('表头字段大小写与连字符不敏感', () {
      const String csv = 'Type,Stem,Paper-Set,Answer\n单选,题干内容,4,A\n';
      final ImportResult r = ImportService().parseText(csv, 'q.csv');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      expect(r.questions.first.paperSet, 4);
      expect(r.questions.first.type, '单选');
    });

    test('空题干行被跳过', () {
      const String csv = 'type,stem,answer\n'
          '单选,,A\n'
          '单选,有效题,B\n';
      final ImportResult r = ImportService().parseText(csv, 'q.csv');
      expect(r.hasError, isFalse);
      expect(r.questions, hasLength(1));
      expect(r.questions.first.stem, '有效题');
      expect(r.skipped, 1);
    });

    test('空 CSV 返回错误', () {
      final ImportResult r = ImportService().parseText('', 'q.csv');
      expect(r.hasError, isTrue);
    });

    test('文件名后缀决定解析器', () {
      const String json = '[{"type":"单选","stem":"s","answer":"A"}]';
      expect(
        ImportService().parseText(json, 'q.json').questions,
        hasLength(1),
      );
      expect(
        ImportService().parseText(json, 'q.txt').questions,
        hasLength(1),
      );
      // 同样的内容按 CSV 解析时首行会被当作表头。
      expect(
        ImportService().parseText(json, 'q.csv').questions,
        isEmpty,
      );
    });
  });

  group('去重', () {
    test('dedupKey 使用题型 + 共用题干 + 去空白题干', () {
      final Question q = Question(
        paperSet: 0,
        type: QuestionType.single,
        stem: ' 同一题干 ',
        answer: 'A',
      );
      expect(ImportService.dedupKey(q), '单选||同一题干');
    });

    test('共用题干题同名子题按 groupStem 区分', () {
      final Question q1 = Question(
        paperSet: 0,
        type: QuestionType.sharedStem,
        groupStem: '肺动脉CTA材料',
        stem: '对比剂注射方案宜为',
        answer: 'A',
      );
      final Question q2 = Question(
        paperSet: 0,
        type: QuestionType.sharedStem,
        groupStem: '下肢动脉CTA材料',
        stem: '对比剂注射方案宜为',
        answer: 'A',
      );
      expect(ImportService.dedupKey(q1), isNot(equals(ImportService.dedupKey(q2))));
    });

    test('deduplicate 过滤重复并统计', () {
      final Question existing = Question(
        paperSet: 0,
        type: QuestionType.single,
        stem: '同一题干',
        answer: 'A',
      );
      final Question dup = Question(
        paperSet: 0,
        type: QuestionType.single,
        stem: ' 同一题干 ',
        answer: 'B',
      );
      final Question fresh = Question(
        paperSet: 0,
        type: QuestionType.term,
        stem: '另一题',
        answer: 'x',
      );

      final ({List<Question> unique, int duplicates}) result =
          ImportService.deduplicate(<Question>[dup, fresh], <Question>[existing]);

      expect(result.duplicates, 1);
      expect(result.unique, hasLength(1));
      expect(result.unique.first.stem, '另一题');
    });
  });
}
