/// 背诵知识卡片模型。
///
/// [title] 为卡片正面（关键词/主题），[content] 为卡片背面（详细内容）。
class KnowledgeCard {
  const KnowledgeCard({
    required this.chapter,
    required this.title,
    required this.content,
  });

  /// 所属章节。
  final String chapter;

  /// 卡片标题（正面）。
  final String title;

  /// 卡片内容（背面）。
  final String content;
}

/// 背诵章节模型，用于章节列表页。
class KnowledgeChapter {
  const KnowledgeChapter({
    required this.name,
    required this.cards,
  });

  /// 章节名称。
  final String name;

  /// 章节下的卡片。
  final List<KnowledgeCard> cards;
}
