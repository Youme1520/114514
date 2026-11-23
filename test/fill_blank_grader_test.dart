import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/utils/fill_blank_grader.dart';

void main() {
  group('FillBlankGrader.splitBlanks', () {
    test('中文分号分隔', () {
      expect(FillBlankGrader.splitBlanks('贴近；平行'), <String>['贴近', '平行']);
    });

    test('英文分号分隔并去除空白与空项', () {
      expect(
        FillBlankGrader.splitBlanks(' a ; ; b ; c '),
        <String>['a', 'b', 'c'],
      );
    });

    test('单个空位', () {
      expect(FillBlankGrader.splitBlanks('平行于滤线栅条'), <String>['平行于滤线栅条']);
    });

    test('空字符串返回空列表', () {
      expect(FillBlankGrader.splitBlanks(''), isEmpty);
    });
  });

  group('FillBlankGrader.normalize', () {
    test('去除首尾空白并转小写', () {
      expect(FillBlankGrader.normalize('  ABC  '), 'abc');
    });

    test('全角字母数字转半角', () {
      expect(FillBlankGrader.normalize('ＡＢＣ１２３'), 'abc123');
    });

    test('全角波浪线转半角', () {
      expect(FillBlankGrader.normalize('３５～４５'), '35~45');
    });

    test('全角空格转半角', () {
      expect(FillBlankGrader.normalize('1.0　cm'), '1.0 cm');
    });

    test('合并连续空白', () {
      expect(FillBlankGrader.normalize('a   b'), 'a b');
    });
  });

  group('FillBlankGrader.isBlankCorrect', () {
    test('去除首尾空白', () {
      expect(FillBlankGrader.isBlankCorrect(' 平行 ', '平行'), isTrue);
    });

    test('大小写不敏感', () {
      expect(FillBlankGrader.isBlankCorrect('abc', 'ABC'), isTrue);
    });

    test('全角半角兼容', () {
      expect(FillBlankGrader.isBlankCorrect('３５～４５', '35~45'), isTrue);
      expect(FillBlankGrader.isBlankCorrect('Ｘ线辐射剂量', 'X线辐射剂量'), isTrue);
    });

    test('不匹配返回 false', () {
      expect(FillBlankGrader.isBlankCorrect('35-45', '35~45'), isFalse);
    });
  });

  group('FillBlankGrader.grade', () {
    test('全部答对', () {
      final FillBlankResult r = FillBlankGrader.grade(
        userAnswer: '贴近；平行',
        correctAnswer: '贴近；平行',
        totalScore: 2,
      );
      expect(r.correctCount, 2);
      expect(r.totalCount, 2);
      expect(r.earnedScore, 2.0);
      expect(r.allCorrect, isTrue);
    });

    test('部分答对按空位均摊得分', () {
      final FillBlankResult r = FillBlankGrader.grade(
        userAnswer: '贴近；错误',
        correctAnswer: '贴近；平行',
        totalScore: 2,
      );
      expect(r.correctCount, 1);
      expect(r.totalCount, 2);
      expect(r.earnedScore, 1.0);
      expect(r.allCorrect, isFalse);
    });

    test('用户少填按未作答处理', () {
      final FillBlankResult r = FillBlankGrader.grade(
        userAnswer: '贴近',
        correctAnswer: '贴近；平行',
        totalScore: 2,
      );
      expect(r.correctCount, 1);
      expect(r.totalCount, 2);
    });

    test('全角与大小写兼容的整题判分', () {
      final FillBlankResult r = FillBlankGrader.grade(
        userAnswer: 'Ｘ线辐射剂量',
        correctAnswer: 'X线辐射剂量',
        totalScore: 1,
      );
      expect(r.correctCount, 1);
      expect(r.allCorrect, isTrue);
    });

    test('空答案全错', () {
      final FillBlankResult r = FillBlankGrader.grade(
        userAnswer: '',
        correctAnswer: '贴近；平行',
        totalScore: 2,
      );
      expect(r.correctCount, 0);
      expect(r.earnedScore, 0.0);
    });
  });
}
