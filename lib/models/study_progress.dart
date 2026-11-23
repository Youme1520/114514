import 'dart:convert';

/// 学习进度种类。
///
/// [paper] 表示整套试卷刷题，[type] 表示分题型刷题，[memorize] 表示章节背诵。
class ProgressKind {
  ProgressKind._();

  static const String paper = 'paper';
  static const String type = 'type';
  static const String memorize = 'memorize';
}

/// 断点续传进度模型。
///
/// 用于在 SharedPreferences 中持久化当前刷题/背诵位置，下次打开 App 时恢复。
class StudyProgress {
  const StudyProgress({
    required this.kind,
    required this.title,
    required this.identifier,
    this.chapter = '',
    this.currentIndex = 0,
    this.totalCount = 0,
    this.randomOrder = false,
    this.randomSeed = 0,
    this.updatedAt = 0,
  });

  /// 进度种类，取值见 [ProgressKind]。
  final String kind;

  /// 展示标题，例如「第1套 · 整套练习」「单选 · 专项练习」「DR检查原则」。
  final String title;

  /// 用于重建题目的标识：
  /// 刷题为套次（字符串）或题型名，背诵为章节名。
  final String identifier;

  /// 当前章节（背诵模块使用，其余为空）。
  final String chapter;

  /// 当前题号 / 卡片页码（从 0 开始）。
  final int currentIndex;

  /// 总题数 / 总卡片数。
  final int totalCount;

  /// 是否随机顺序模式。
  final bool randomOrder;

  /// 随机顺序使用的种子（0 表示未启用随机）。
  final int randomSeed;

  /// 最后更新时间（毫秒时间戳）。
  final int updatedAt;

  bool get isValid =>
      kind.isNotEmpty && identifier.isNotEmpty && totalCount > 0;

  /// 序列化为 JSON 字符串（键名稳定，便于持久化）。
  String toJsonString() => jsonEncode(toJson());

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind,
        'title': title,
        'identifier': identifier,
        'chapter': chapter,
        'currentIndex': currentIndex,
        'totalCount': totalCount,
        'randomOrder': randomOrder,
        'randomSeed': randomSeed,
        'updatedAt': updatedAt,
      };

  /// 从 JSON 字符串构造（带容错，解析失败返回 null）。
  static StudyProgress? fromJsonString(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    try {
      final Map<String, dynamic> map =
          jsonDecode(source) as Map<String, dynamic>;
      return StudyProgress(
        kind: (map['kind'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        identifier: (map['identifier'] as String?) ?? '',
        chapter: (map['chapter'] as String?) ?? '',
        currentIndex: ((map['currentIndex'] as num?) ?? 0).toInt(),
        totalCount: ((map['totalCount'] as num?) ?? 0).toInt(),
        randomOrder: (map['randomOrder'] as bool?) ?? false,
        randomSeed: ((map['randomSeed'] as num?) ?? 0).toInt(),
        updatedAt: ((map['updatedAt'] as num?) ?? 0).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  StudyProgress copyWith({
    String? kind,
    String? title,
    String? identifier,
    String? chapter,
    int? currentIndex,
    int? totalCount,
    bool? randomOrder,
    int? randomSeed,
    int? updatedAt,
  }) {
    return StudyProgress(
      kind: kind ?? this.kind,
      title: title ?? this.title,
      identifier: identifier ?? this.identifier,
      chapter: chapter ?? this.chapter,
      currentIndex: currentIndex ?? this.currentIndex,
      totalCount: totalCount ?? this.totalCount,
      randomOrder: randomOrder ?? this.randomOrder,
      randomSeed: randomSeed ?? this.randomSeed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
