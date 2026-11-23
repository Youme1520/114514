import 'question.dart';

/// 试卷模型，表示一套完整的内置试卷。
class Paper {
  const Paper({
    required this.set,
    required this.title,
    required this.scope,
    required this.questions,
  });

  /// 套次（1～5）。
  final int set;

  /// 试卷标题。
  final String title;

  /// 本套考查范围说明。
  final String scope;

  /// 题目列表。
  final List<Question> questions;

  /// 试卷总分。
  int get totalScore => questions.fold<int>(
        0,
        (int sum, Question q) => sum + q.score.round(),
      );

  /// 客观题数量。
  int get objectiveCount =>
      questions.where((Question q) => q.isObjective).length;

  /// 主观题数量。
  int get subjectiveCount =>
      questions.where((Question q) => q.isSubjective).length;
}
