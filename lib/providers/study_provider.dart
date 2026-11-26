import 'package:flutter/foundation.dart';

import '../data/chapter_data.dart';
import '../data/exam_data.dart';
import '../data/knowledge_data.dart';
import '../models/knowledge_card.dart';
import '../models/paper.dart';
import '../models/question.dart';
import '../models/study_progress.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import '../services/settings_service.dart';

/// 学习状态：内置试卷、导入题库、背诵进度与导入操作。
class StudyProvider extends ChangeNotifier {
  StudyProvider({required DatabaseService db, required SettingsService settings})
      : _db = db,
        _settings = settings;

  final DatabaseService _db;
  final SettingsService _settings;

  List<Question> _imported = <Question>[];
  Set<int> _memorized = <int>{};
  bool _loaded = false;

  /// 内置试卷（新版 1～5 + 旧版 6～10）。
  List<Paper> get papers => allBuiltinPapers;

  /// 背诵章节。
  List<KnowledgeChapter> get chapters => knowledgeChapters;

  /// 全部背诵卡片。
  List<KnowledgeCard> get allCards => allKnowledgeCards;

  /// 全部内置题目。
  List<Question> get builtinQuestions =>
      <Question>[for (final Paper p in allBuiltinPapers) ...p.questions];

  /// 分章节题库（章节名 → 题目列表，数据来自 `lib/data/chapter_data.dart`）。
  Map<String, List<Question>> get chapterQuestions =>
      ChapterQuestionBank.chapterQuestions;

  /// 分章节题库的章节名（按顺序排列）。
  List<String> get chapterNames => ChapterQuestionBank.allChapters;

  /// 分章节题库总题数。
  int get totalChapterQuestions => ChapterQuestionBank.totalCount;

  /// 指定章节的分章节题库题目数。
  int chapterQuestionCount(String chapter) => ChapterQuestionBank.countOf(chapter);

  /// 按套次查找内置试卷。
  Paper? paperBySet(int set) {
    for (final Paper p in allBuiltinPapers) {
      if (p.set == set) return p;
    }
    return null;
  }

  /// 按名称查找背诵章节。
  KnowledgeChapter? chapterByName(String name) {
    for (final KnowledgeChapter c in knowledgeChapters) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// 根据断点续传进度重建题目列表（用于恢复刷题）。
  List<Question> resumeQuestionsFor(StudyProgress progress) {
    switch (progress.kind) {
      case ProgressKind.paper:
        final Paper? paper = paperBySet(int.tryParse(progress.identifier) ?? -1);
        return paper?.questions ?? const <Question>[];
      case ProgressKind.type:
        return questionsByType(progress.identifier);
      case ProgressKind.chapter:
        return questionsByChapter(progress.identifier);
      default:
        return const <Question>[];
    }
  }

  /// 导入题目（不可变视图）。
  List<Question> get importedQuestions => List<Question>.unmodifiable(_imported);

  /// 内置题总数。
  int get totalBuiltinQuestions => builtinQuestions.length;

  /// 题目总数（内置试卷 + 分章节题库 + 导入）。
  int get totalQuestions =>
      totalBuiltinQuestions + totalChapterQuestions + _imported.length;

  /// 已掌握卡片索引。
  Set<int> get memorizedIndexes => Set<int>.unmodifiable(_memorized);

  int get memorizedCount => _memorized.length;

  int get totalCards => allKnowledgeCards.length;

  bool isMemorized(int index) => _memorized.contains(index);

  /// 初始化：加载导入题库与背诵进度。
  Future<void> init() async {
    if (_loaded) return;
    _imported = await _db.getImportedQuestions();
    _memorized = await _settings.getMemorized();
    _loaded = true;
    notifyListeners();
  }

  /// 按题型筛选（内置试卷 + 导入题库 + 分章节题库）。
  List<Question> questionsByType(String type) {
    final List<Question> result = builtinQuestions
        .where((Question q) => q.type == type)
        .toList();
    result.addAll(_imported.where((Question q) => q.type == type));
    for (final List<Question> list
        in ChapterQuestionBank.chapterQuestions.values) {
      result.addAll(list.where((Question q) => q.type == type));
    }
    return result;
  }

  /// 按章节筛选（内置试卷 + 导入题库 + 分章节题库）。
  List<Question> questionsByChapter(String chapter) {
    final List<Question> result = builtinQuestions
        .where((Question q) => q.chapter == chapter)
        .toList();
    result.addAll(_imported.where((Question q) => q.chapter == chapter));
    result.addAll(
      ChapterQuestionBank.chapterQuestions[chapter] ?? const <Question>[],
    );
    return result;
  }

  /// 选择文件并导入题库（自动去重、跳过无效行）。
  Future<ImportResult> importFromFile() async {
    final ImportService service = ImportService();
    final ImportResult result = await service.pickAndParse();
    if (result.hasError || result.questions.isEmpty) {
      return result;
    }

    final Iterable<Question> existing = <Question>[
      ...builtinQuestions,
      ..._imported,
      for (final List<Question> list in ChapterQuestionBank.chapterQuestions.values)
        ...list,
    ];
    final ({List<Question> unique, int duplicates}) deduped =
        ImportService.deduplicate(result.questions, existing);

    if (deduped.unique.isNotEmpty) {
      await _db.insertImportedQuestions(deduped.unique);
      _imported = await _db.getImportedQuestions();
      notifyListeners();
    }
    return result.copyWith(duplicates: deduped.duplicates);
  }

  /// 删除单条导入题目。
  Future<void> removeImportedQuestion(int id) async {
    await _db.deleteImportedQuestion(id);
    _imported = await _db.getImportedQuestions();
    notifyListeners();
  }

  /// 清空导入题库。
  Future<void> clearImported() async {
    await _db.clearImportedQuestions();
    _imported = <Question>[];
    notifyListeners();
  }

  /// 切换某张卡片的掌握状态。
  Future<void> toggleMemorized(int index) async {
    if (_memorized.contains(index)) {
      _memorized.remove(index);
    } else {
      _memorized.add(index);
    }
    notifyListeners();
    await _settings.setMemorized(_memorized);
  }
}
