import 'dart:convert';

/// 题型常量定义。
///
/// 题库包含六种题型：单选题、共用题干选择题、填空题、名词解释、简答题、分析题。
/// 其中单选、共用题干与填空为客观题（可自动判分），其余为主观题（需自评或 AI 批改）。
class QuestionType {
  QuestionType._();

  static const String single = '单选';
  static const String sharedStem = '共用题干选择';
  static const String fillBlank = '填空';
  static const String term = '名词解释';
  static const String shortAnswer = '简答';
  static const String analysis = '分析题';

  static const List<String> all = <String>[
    single,
    sharedStem,
    fillBlank,
    term,
    shortAnswer,
    analysis,
  ];

  /// 判断是否为客观题（单选/共用题干选择/填空）。
  static bool isObjective(String type) =>
      type == single || type == sharedStem || type == fillBlank;

  /// 判断是否为主观题（名词解释/简答/分析题）。
  static bool isSubjective(String type) =>
      type == term || type == shortAnswer || type == analysis;
}

/// 题目来源。
class QuestionSource {
  QuestionSource._();

  static const String builtin = 'builtin';
  static const String imported = 'imported';
}

/// 题目数据模型。
///
/// 客观题 [options] 存选项文本，[answer] 存选项字母（A/B/C/D）；
/// 填空题 [options] 为空，[answer] 用「；」分隔多个空位的答案；
/// 主观题 [options] 为空，[answer] 存参考答案全文。
class Question {
  const Question({
    this.id,
    required this.paperSet,
    required this.type,
    this.chapter = '',
    required this.stem,
    this.groupStem,
    this.options = const <String>[],
    required this.answer,
    this.analysis = '',
    this.score = 0,
    this.source = QuestionSource.builtin,
  });

  /// 数据库主键（内置题为 null，导入题为自增 id）。
  final int? id;

  /// 套次，1～10 为内置试卷，0 表示导入题。
  final int paperSet;

  /// 题型，取值见 [QuestionType]。
  final String type;

  /// 章节（导入题可自定义，内置题用于描述考查范围）。
  final String chapter;

  /// 题干。
  final String stem;

  /// 共用题干（共用题干选择题所属的材料，其余题型为 null）。
  final String? groupStem;

  /// 选项列表（客观题）。
  final List<String> options;

  /// 答案：选择题为字母，填空题为「；」分隔的空位答案，主观题为参考答案全文。
  final String answer;

  /// 解析 / 评分要点。
  final String analysis;

  /// 分值。
  final double score;

  /// 来源：builtin / imported。
  final String source;

  bool get isObjective => QuestionType.isObjective(type);

  bool get isSubjective => QuestionType.isSubjective(type);

  /// 是否为填空题（客观题中的特殊题型，需要逐空判分）。
  bool get isFillBlank => type == QuestionType.fillBlank;

  /// 填空题各空位答案（按「；」或「;」拆分，去除首尾空白与空项）。
  List<String> get fillBlankAnswers {
    if (!isFillBlank) return const <String>[];
    return answer
        .split(RegExp(r'[；;]'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .toList();
  }

  /// 转换为数据库 Map（选项序列化为 JSON 字符串）。
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'paper_set': paperSet,
      'type': type,
      'chapter': chapter,
      'stem': stem,
      'group_stem': groupStem,
      'options': jsonEncode(options),
      'answer': answer,
      'analysis': analysis,
      'score': score,
      'source': source,
    };
  }

  /// 从数据库 Map 构造（选项由 JSON 字符串反序列化）。
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      paperSet: (map['paper_set'] as int?) ?? 0,
      type: (map['type'] as String?) ?? '',
      chapter: (map['chapter'] as String?) ?? '',
      stem: (map['stem'] as String?) ?? '',
      groupStem: map['group_stem'] as String?,
      options: _decodeOptions(map['options']),
      answer: (map['answer'] as String?) ?? '',
      analysis: (map['analysis'] as String?) ?? '',
      score: ((map['score'] as num?) ?? 0).toDouble(),
      source: (map['source'] as String?) ?? QuestionSource.imported,
    );
  }

  /// 转换为可导入/导出的 JSON Map。
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'paperSet': paperSet,
      'chapter': chapter,
      'stem': stem,
      'groupStem': groupStem,
      'options': options,
      'answer': answer,
      'analysis': analysis,
      'score': score,
    };
  }

  /// 从 JSON Map 构造（兼容中英文字段名与多种选项格式）。
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      paperSet: _asInt(_pick(json, <String>['paperSet', 'paper_set', '套次'])) ?? 0,
      type: _asString(_pick(json, <String>['type', '题型'])) ?? QuestionType.single,
      chapter: _asString(_pick(json, <String>['chapter', '章节'])) ?? '',
      stem: _asString(_pick(json, <String>['stem', '题干', '题目'])) ?? '',
      groupStem: _asString(_pick(json, <String>['groupStem', 'group_stem', '共用题干'])),
      options: _parseOptions(_pick(json, <String>['options', '选项'])),
      answer: _asString(_pick(json, <String>['answer', '答案'])) ?? '',
      analysis: _asString(_pick(json, <String>['analysis', '解析'])) ?? '',
      score: _asDouble(_pick(json, <String>['score', '分值'])) ?? 0,
      source: QuestionSource.imported,
    );
  }

  Question copyWith({
    int? id,
    int? paperSet,
    String? type,
    String? chapter,
    String? stem,
    String? groupStem,
    List<String>? options,
    String? answer,
    String? analysis,
    double? score,
    String? source,
  }) {
    return Question(
      id: id ?? this.id,
      paperSet: paperSet ?? this.paperSet,
      type: type ?? this.type,
      chapter: chapter ?? this.chapter,
      stem: stem ?? this.stem,
      groupStem: groupStem ?? this.groupStem,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      analysis: analysis ?? this.analysis,
      score: score ?? this.score,
      source: source ?? this.source,
    );
  }

  static List<String> _decodeOptions(Object? value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value.map((dynamic e) => e.toString()).toList();
    }
    try {
      final List<dynamic> decoded = jsonDecode(value.toString()) as List<dynamic>;
      return decoded.map((dynamic e) => e.toString()).toList();
    } catch (_) {
      return const <String>[];
    }
  }

  /// 从 Map 中按多个候选 key 取值（优先匹配第一个存在的 key）。
  static Object? _pick(Map<String, dynamic> json, List<String> keys) {
    for (final String key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((dynamic e) => e.toString()).join('\n');
    }
    return value.toString().trim();
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  /// 解析选项：支持 List、JSON 字符串、"A.xx|B.xx"、"A.xx\nB.xx" 等格式。
  static List<String> _parseOptions(Object? value) {
    if (value == null) return const <String>[];
    if (value is List) {
      return value.map((dynamic e) => e.toString().trim()).toList();
    }
    final String raw = value.toString().trim();
    if (raw.isEmpty) return const <String>[];
    // 尝试按 JSON 数组解析。
    if (raw.startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((dynamic e) => e.toString().trim()).toList();
      } catch (_) {
        // 解析失败则回退到分隔符方案。
      }
    }
    // 统一分隔符：换行、|、;（中文或英文），并去除形如 "A." 的字母前缀。
    final List<String> parts = raw
        .split(RegExp(r'[\r\n|;；]'))
        .map((String e) => e.trim())
        .where((String e) => e.isNotEmpty)
        .map((String e) => e.replaceFirst(RegExp(r'^[A-Za-z]\s*[.．、：:)]\s*'), ''))
        .toList();
    return parts;
  }
}
