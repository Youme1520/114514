import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/models/question.dart';

void main() {
  group('QuestionType', () {
    test('客观题与主观题判断', () {
      expect(QuestionType.isObjective(QuestionType.single), isTrue);
      expect(QuestionType.isObjective(QuestionType.sharedStem), isTrue);
      expect(QuestionType.isObjective(QuestionType.fillBlank), isTrue);
      expect(QuestionType.isObjective(QuestionType.term), isFalse);
      expect(QuestionType.isSubjective(QuestionType.term), isTrue);
      expect(QuestionType.isSubjective(QuestionType.shortAnswer), isTrue);
      expect(QuestionType.isSubjective(QuestionType.analysis), isTrue);
      expect(QuestionType.isSubjective(QuestionType.single), isFalse);
      expect(QuestionType.isSubjective(QuestionType.fillBlank), isFalse);
    });

    test('填空题空位答案拆分', () {
      const Question q = Question(
        paperSet: 1,
        type: QuestionType.fillBlank,
        stem: '摄影时肢体________并与探测器________。',
        answer: '贴近；平行',
        score: 2,
      );
      expect(q.isFillBlank, isTrue);
      expect(q.fillBlankAnswers, <String>['贴近', '平行']);
    });
  });

  group('Question.fromJson 中英文字段映射', () {
    test('中文字段名', () {
      final Question q = Question.fromJson(<String, dynamic>{
        '套次': 3,
        '题型': '简答',
        '章节': '影像技术基础',
        '题干': '简述CT值',
        '共用题干': '某患者材料',
        '选项': 'A. 空气\nB. 水',
        '答案': '参考答案全文',
        '解析': '解析内容',
        '分值': 6,
      });

      expect(q.paperSet, 3);
      expect(q.type, '简答');
      expect(q.chapter, '影像技术基础');
      expect(q.stem, '简述CT值');
      expect(q.groupStem, '某患者材料');
      expect(q.options, <String>['空气', '水']);
      expect(q.answer, '参考答案全文');
      expect(q.analysis, '解析内容');
      expect(q.score, 6.0);
      expect(q.source, QuestionSource.imported);
    });

    test('英文字段名', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'paperSet': 1,
        'type': '单选',
        'chapter': 'chapter-a',
        'stem': 'stem text',
        'groupStem': 'group text',
        'options': <String>['opt1', 'opt2'],
        'answer': 'A',
        'analysis': 'analysis text',
        'score': 2,
      });

      expect(q.paperSet, 1);
      expect(q.type, '单选');
      expect(q.chapter, 'chapter-a');
      expect(q.stem, 'stem text');
      expect(q.groupStem, 'group text');
      expect(q.options, <String>['opt1', 'opt2']);
      expect(q.answer, 'A');
      expect(q.analysis, 'analysis text');
      expect(q.score, 2.0);
      expect(q.source, QuestionSource.imported);
    });

    test('中英文并存时优先英文字段（pick 顺序）', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'english stem',
        '题干': '中文题干',
      });
      expect(q.stem, 'english stem');
    });

    test('缺少字段时使用默认值', () {
      final Question q = Question.fromJson(<String, dynamic>{'题干': 'x'});
      expect(q.paperSet, 0);
      expect(q.type, QuestionType.single);
      expect(q.options, isEmpty);
      expect(q.answer, '');
      expect(q.score, 0.0);
    });

    test('填空题题型与分号答案解析', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'type': '填空',
        'stem': '摄影时肢体________探测器。',
        'answer': '贴近；平行',
        'score': 2,
      });
      expect(q.type, QuestionType.fillBlank);
      expect(q.isFillBlank, isTrue);
      expect(q.isObjective, isTrue);
      expect(q.fillBlankAnswers, <String>['贴近', '平行']);
    });
  });

  group('选项解析 _parseOptions（经 fromJson 触发）', () {
    test('JSON 数组字符串', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': '["A. 甲", "B. 乙"]',
      });
      expect(q.options, <String>['A. 甲', 'B. 乙']);
    });

    test('List 输入仅去首尾空白', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': <String>[' A. 甲 ', ' B. 乙 '],
      });
      expect(q.options, <String>['A. 甲', 'B. 乙']);
    });

    test('竖线分隔并去除字母前缀', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': 'A. 空气|B. 水|C. 骨|D. 脂肪',
      });
      expect(q.options, <String>['空气', '水', '骨', '脂肪']);
    });

    test('换行分隔', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': 'A. 甲\nB. 乙\nC. 丙',
      });
      expect(q.options, <String>['甲', '乙', '丙']);
    });

    test('中文分号与全角点号', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': 'A．甲；B．乙；C．丙',
      });
      expect(q.options, <String>['甲', '乙', '丙']);
    });

    test('支持多种前缀符号', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': 'A、甲|B) 乙|C: 丙',
      });
      expect(q.options, <String>['甲', '乙', '丙']);
    });

    test('空选项返回空列表', () {
      final Question q = Question.fromJson(<String, dynamic>{
        'stem': 'x',
        'options': '',
      });
      expect(q.options, isEmpty);
    });
  });

  group('toMap / fromMap 往返', () {
    test('字段完整往返', () {
      final Question q = Question(
        id: 7,
        paperSet: 2,
        type: QuestionType.single,
        chapter: '章节',
        stem: '题干',
        groupStem: '材料',
        options: const <String>['甲', '乙'],
        answer: 'B',
        analysis: '解析',
        score: 2.5,
        source: QuestionSource.imported,
      );

      final Map<String, dynamic> map = q.toMap();
      expect(map['id'], 7);
      expect(map['options'], '["甲","乙"]');

      final Question restored = Question.fromMap(map);
      expect(restored.id, 7);
      expect(restored.paperSet, 2);
      expect(restored.type, QuestionType.single);
      expect(restored.chapter, '章节');
      expect(restored.stem, '题干');
      expect(restored.groupStem, '材料');
      expect(restored.options, <String>['甲', '乙']);
      expect(restored.answer, 'B');
      expect(restored.analysis, '解析');
      expect(restored.score, 2.5);
      expect(restored.source, QuestionSource.imported);
    });

    test('options 为空时 fromMap 返回空列表', () {
      final Question q = Question.fromMap(<String, dynamic>{
        'paper_set': 0,
        'type': '单选',
        'stem': 's',
        'options': null,
        'answer': 'A',
      });
      expect(q.options, isEmpty);
    });
  });

  group('copyWith', () {
    test('覆盖指定字段并保留其它字段', () {
      final Question q = Question(
        id: 1,
        paperSet: 1,
        type: QuestionType.single,
        chapter: 'c',
        stem: 's',
        answer: 'A',
        score: 2,
      );
      final Question c = q.copyWith(stem: 's2', answer: 'B', score: 3.0);
      expect(c.id, 1);
      expect(c.paperSet, 1);
      expect(c.type, QuestionType.single);
      expect(c.chapter, 'c');
      expect(c.stem, 's2');
      expect(c.answer, 'B');
      expect(c.score, 3.0);
    });
  });

  group('toJson', () {
    test('输出 JSON 字段', () {
      final Question q = Question(
        paperSet: 1,
        type: QuestionType.single,
        stem: 's',
        options: const <String>['a', 'b'],
        answer: 'A',
      );
      final Map<String, dynamic> json = q.toJson();
      expect(json['type'], '单选');
      expect(json['paperSet'], 1);
      expect(json['options'], <String>['a', 'b']);
      expect(json.containsKey('id'), isFalse);
    });
  });
}
