/// 多选题（X 型题）判分工具（纯 Dart，无 Flutter 依赖，便于单元测试）。
///
/// 判分规则：
/// - 答案存储为字母集合，支持 "ABDE"、"A,B,D,E"、"A B D E" 等格式；
/// - 严格全对才得分：全部选对得分，少选、错选、多选均不得分；
/// - 解析结果去除分隔符、空白并统一大写后按字母去重。
library;

/// 多选题判分器。
class MultiChoiceGrader {
  MultiChoiceGrader._();

  /// 将答案字符串解析为字母集合（去重、去空白与分隔符、统一大写）。
  ///
  /// 支持 "ABDE"、"A,B,D,E"、"A B D E"、"A；B；D；E" 等常见格式，
  /// 仅保留 A～Z 字母。
  static Set<String> parseLetters(String answer) {
    final String cleaned = answer
        .replaceAll(RegExp(r'[\s,，;；、/|]'), '')
        .toUpperCase();
    final Set<String> letters = <String>{};
    for (final int code in cleaned.runes) {
      final String ch = String.fromCharCode(code);
      if (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) {
        letters.add(ch);
      }
    }
    return letters;
  }

  /// 将字母集合规范化为有序字符串（如 "ABDE"），用于存储与比较。
  static String normalizeLetters(Set<String> letters) {
    final List<String> sorted = letters.toList()..sort();
    return sorted.join();
  }

  /// 判断用户选择集合与正确答案集合是否完全一致。
  ///
  /// 全部选对（集合相等）返回 true；少选、错选、多选均返回 false。
  static bool isCorrect(Set<String> user, String correctAnswer) {
    final Set<String> correct = parseLetters(correctAnswer);
    if (correct.isEmpty) return false;
    if (user.length != correct.length) return false;
    return correct.containsAll(user);
  }

  /// 综合判分：全对得 [totalScore]，否则得 0。
  static double grade({
    required Set<String> user,
    required String correctAnswer,
    required double totalScore,
  }) {
    return isCorrect(user, correctAnswer) ? totalScore : 0;
  }
}
