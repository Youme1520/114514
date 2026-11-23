/// 填空题判分工具（纯 Dart，无 Flutter 依赖，便于单元测试）。
///
/// 判分规则：
/// - 空位答案以「；」或「;」分隔；
/// - 单个空位比对：去除首尾空白、大小写不敏感、全角/半角兼容；
/// - 每空分值 = 题目总分 / 空位数（内置数据每空 1 分）。
library;

/// 填空题判分结果。
class FillBlankResult {
  const FillBlankResult({
    required this.correctCount,
    required this.totalCount,
    required this.earnedScore,
  });

  /// 答对的空位数。
  final int correctCount;

  /// 总空位数。
  final int totalCount;

  /// 按空位比例计算的得分。
  final double earnedScore;

  /// 是否全部答对。
  bool get allCorrect => totalCount > 0 && correctCount == totalCount;
}

/// 填空题判分器。
class FillBlankGrader {
  FillBlankGrader._();

  /// 将答案按「；」或「;」拆分为空位列表（去除首尾空白与空项）。
  static List<String> splitBlanks(String answer) {
    return answer
        .split(RegExp(r'[；;]'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  /// 文本规范化：去首尾空白、转小写、全角转半角、合并连续空白。
  static String normalize(String value) {
    return _toHalfWidth(value.trim().toLowerCase())
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 判断单个空位是否答对。
  static bool isBlankCorrect(String input, String expected) {
    return normalize(input) == normalize(expected);
  }

  /// 判分：比较用户答案与参考答案，返回逐空比对结果与得分。
  ///
  /// [userAnswer] 为用户按「；」分隔输入的内容，[correctAnswer] 为参考答案，
  /// [totalScore] 为该填空题总分（按空位数均摊）。
  static FillBlankResult grade({
    required String userAnswer,
    required String correctAnswer,
    required double totalScore,
  }) {
    final List<String> correctBlanks = splitBlanks(correctAnswer);
    final List<String> userBlanks = splitBlanks(userAnswer);
    int correct = 0;
    for (int i = 0; i < correctBlanks.length; i++) {
      final String user = i < userBlanks.length ? userBlanks[i] : '';
      if (isBlankCorrect(user, correctBlanks[i])) correct++;
    }
    final double perBlank =
        correctBlanks.isEmpty ? 0 : totalScore / correctBlanks.length;
    return FillBlankResult(
      correctCount: correct,
      totalCount: correctBlanks.length,
      earnedScore: correct * perBlank,
    );
  }

  /// 全角 ASCII 字符转半角（U+FF01～U+FF5E → U+0021～U+007E，全角空格 → 半角空格）。
  static String _toHalfWidth(String value) {
    final StringBuffer buffer = StringBuffer();
    for (final int code in value.runes) {
      if (code == 0x3000) {
        buffer.write(' ');
      } else if (code >= 0xFF01 && code <= 0xFF5E) {
        buffer.writeCharCode(code - 0xFEE0);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }
}
