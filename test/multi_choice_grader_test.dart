import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/utils/multi_choice_grader.dart';

void main() {
  group('MultiChoiceGrader.parseLetters 答案字母解析', () {
    test('紧凑格式 "ABDE"', () {
      expect(MultiChoiceGrader.parseLetters('ABDE'), <String>{'A', 'B', 'D', 'E'});
    });

    test('英文逗号分隔 "A,B,D,E"', () {
      expect(
        MultiChoiceGrader.parseLetters('A,B,D,E'),
        <String>{'A', 'B', 'D', 'E'},
      );
    });

    test('中文逗号分隔 "A，B，D，E"', () {
      expect(
        MultiChoiceGrader.parseLetters('A，B，D，E'),
        <String>{'A', 'B', 'D', 'E'},
      );
    });

    test('空格分隔 "A B D E"', () {
      expect(
        MultiChoiceGrader.parseLetters('A B D E'),
        <String>{'A', 'B', 'D', 'E'},
      );
    });

    test('中文分号分隔 "A；B；D；E"', () {
      expect(
        MultiChoiceGrader.parseLetters('A；B；D；E'),
        <String>{'A', 'B', 'D', 'E'},
      );
    });

    test('小写自动转大写', () {
      expect(
        MultiChoiceGrader.parseLetters('abde'),
        <String>{'A', 'B', 'D', 'E'},
      );
    });

    test('重复字母去重', () {
      expect(MultiChoiceGrader.parseLetters('A,B,A'), <String>{'A', 'B'});
    });

    test('忽略非字母字符（数字/标点）', () {
      expect(MultiChoiceGrader.parseLetters('A 1 B 2'), <String>{'A', 'B'});
    });

    test('空字符串返回空集合', () {
      expect(MultiChoiceGrader.parseLetters(''), isEmpty);
    });
  });

  group('MultiChoiceGrader.normalizeLetters', () {
    test('乱序集合规范化为有序字符串', () {
      expect(MultiChoiceGrader.normalizeLetters(<String>{'E', 'A', 'B', 'D'}), 'ABDE');
    });

    test('空集合返回空字符串', () {
      expect(MultiChoiceGrader.normalizeLetters(<String>{}), '');
    });
  });

  group('MultiChoiceGrader.isCorrect 严格判分', () {
    test('全部选对返回 true', () {
      expect(
        MultiChoiceGrader.isCorrect(<String>{'A', 'B', 'D', 'E'}, 'ABDE'),
        isTrue,
      );
    });

    test('选择顺序不影响判定', () {
      expect(
        MultiChoiceGrader.isCorrect(<String>{'E', 'D', 'B', 'A'}, 'ABDE'),
        isTrue,
      );
    });

    test('漏选（部分选对）返回 false', () {
      expect(MultiChoiceGrader.isCorrect(<String>{'A', 'B'}, 'ABDE'), isFalse);
    });

    test('错选返回 false', () {
      expect(MultiChoiceGrader.isCorrect(<String>{'A', 'C'}, 'ABDE'), isFalse);
    });

    test('多选返回 false', () {
      expect(
        MultiChoiceGrader.isCorrect(<String>{'A', 'B', 'C', 'D', 'E'}, 'ABDE'),
        isFalse,
      );
    });

    test('完全无关的选项返回 false', () {
      expect(MultiChoiceGrader.isCorrect(<String>{'F'}, 'ABDE'), isFalse);
    });

    test('正确答案为空时返回 false', () {
      expect(MultiChoiceGrader.isCorrect(<String>{'A'}, ''), isFalse);
    });
  });

  group('MultiChoiceGrader.grade 综合判分', () {
    test('全部选对得满分', () {
      expect(
        MultiChoiceGrader.grade(
          user: <String>{'A', 'B', 'D', 'E'},
          correctAnswer: 'ABDE',
          totalScore: 4,
        ),
        4.0,
      );
    });

    test('漏选得 0 分', () {
      expect(
        MultiChoiceGrader.grade(
          user: <String>{'A', 'B'},
          correctAnswer: 'ABDE',
          totalScore: 4,
        ),
        0.0,
      );
    });

    test('错选得 0 分', () {
      expect(
        MultiChoiceGrader.grade(
          user: <String>{'A', 'C'},
          correctAnswer: 'ABDE',
          totalScore: 4,
        ),
        0.0,
      );
    });

    test('多选得 0 分', () {
      expect(
        MultiChoiceGrader.grade(
          user: <String>{'A', 'B', 'C', 'D', 'E'},
          correctAnswer: 'ABDE',
          totalScore: 4,
        ),
        0.0,
      );
    });
  });
}
