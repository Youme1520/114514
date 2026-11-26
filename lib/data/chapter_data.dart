import '../models/question.dart';
import 'chapters/chapter01.dart';
import 'chapters/chapter02.dart';
import 'chapters/chapter03.dart';
import 'chapters/chapter04.dart';
import 'chapters/chapter05.dart';
import 'chapters/chapter06.dart';
import 'chapters/chapter07.dart';
import 'chapters/chapter08.dart';
import 'chapters/chapter09.dart';
import 'chapters/chapter10.dart';

/// 分章节题库。
///
/// 数据来源：`D:/MC/_guide_ch1to10.txt`（医学影像检查技术学学习指导与习题集）。
/// 仅提取各章「习题」部分（跳过「学习目标」「重点和难点内容」），并严格按题型归类：
/// - A1/A3/A4 型选择题 → [QuestionType.single]
/// - X 型题 → [QuestionType.multiChoice]
/// - 名词解释 → [QuestionType.term]
/// - 简答题 → [QuestionType.shortAnswer]
/// - 案例分析选择题 → 单选归 [QuestionType.single]，多选归 [QuestionType.multiChoice]
///
/// 所有题目均携带 [Question.chapter] 字段（格式「第X章 标题」），
/// 共用题干存放在 [Question.groupStem]，主观题参考答案存放在 [Question.answer]。
class ChapterQuestionBank {
  ChapterQuestionBank._();

  static const String ch1 = '第一章 绪论';
  static const String ch2 = '第二章 数字X线检查技术';
  static const String ch3 = '第三章 CT检查技术基础';
  static const String ch4 = '第四章 头颈部CT检查技术';
  static const String ch5 = '第五章 胸部CT检查技术';
  static const String ch6 = '第六章 腹部与盆腔CT检查技术';
  static const String ch7 = '第七章 脊柱、四肢骨关节CT检查技术';
  static const String ch8 = '第八章 图像质量控制与融合CT成像技术';
  static const String ch9 = '第九章 DSA检查技术';
  static const String ch10 = '第十章 DSA成像质量控制';

  /// 按顺序排列的章节名。
  static const List<String> allChapters = <String>[
    ch1,
    ch2,
    ch3,
    ch4,
    ch5,
    ch6,
    ch7,
    ch8,
    ch9,
    ch10,
  ];

  /// 章节名 → 题目列表。
  static final Map<String, List<Question>> chapterQuestions =
      <String, List<Question>>{
    ch1: chapter01Questions,
    ch2: chapter02Questions,
    ch3: chapter03Questions,
    ch4: chapter04Questions,
    ch5: chapter05Questions,
    ch6: chapter06Questions,
    ch7: chapter07Questions,
    ch8: chapter08Questions,
    ch9: chapter09Questions,
    ch10: chapter10Questions,
  };

  /// 指定章节的题目数。
  static int countOf(String chapter) => chapterQuestions[chapter]?.length ?? 0;

  /// 分章节题库总题数。
  static int get totalCount {
    int n = 0;
    for (final List<Question> list in chapterQuestions.values) {
      n += list.length;
    }
    return n;
  }
}
