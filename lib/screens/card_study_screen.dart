import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/knowledge_card.dart';
import '../models/study_progress.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';

/// 翻卡背诵页：左右翻页，点击翻面，可标记掌握。
class CardStudyScreen extends StatefulWidget {
  const CardStudyScreen({super.key, required this.chapter, this.initialPage = 0});

  final KnowledgeChapter chapter;

  /// 初始卡片页码（用于断点续传恢复）。
  final int initialPage;

  @override
  State<CardStudyScreen> createState() => _CardStudyScreenState();
}

class _CardStudyScreenState extends State<CardStudyScreen> {
  late final PageController _pageController;
  late int _page;

  @override
  void initState() {
    super.initState();
    final int total = widget.chapter.cards.length;
    _page = widget.initialPage.clamp(0, total == 0 ? 0 : total - 1).toInt();
    _pageController = PageController(initialPage: _page);
    if (total > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _saveProgress(_page);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _saveProgress(int page) {
    context.read<SettingsProvider>().saveStudyProgress(
          StudyProgress(
            kind: ProgressKind.memorize,
            title: widget.chapter.name,
            identifier: widget.chapter.name,
            chapter: widget.chapter.name,
            currentIndex: page,
            totalCount: widget.chapter.cards.length,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  int _globalIndex(KnowledgeCard card) {
    final StudyProvider study = context.read<StudyProvider>();
    for (int i = 0; i < study.allCards.length; i++) {
      if (identical(study.allCards[i], card)) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final StudyProvider study = context.watch<StudyProvider>();
    final List<KnowledgeCard> cards = widget.chapter.cards;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapter.name)),
        body: const EmptyView(icon: Icons.style_outlined, message: '该章节暂无卡片'),
      );
    }
    final KnowledgeCard current = cards[_page];
    final int globalIndex = _globalIndex(current);
    final bool mastered =
        globalIndex >= 0 && study.memorizedIndexes.contains(globalIndex);

    return Scaffold(
      appBar: AppBar(title: Text(widget.chapter.name)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: <Widget>[
                Text(
                  '${_page + 1} / ${cards.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '已掌握 ${study.memorizedCount} / ${study.totalCards}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: cards.isEmpty ? 0 : (_page + 1) / cards.length,
            minHeight: 3,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cards.length,
              onPageChanged: (int i) {
                setState(() => _page = i);
                _saveProgress(i);
              },
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: _FlipCard(card: cards[i]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              children: <Widget>[
                if (_page > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('上一张'),
                    ),
                  ),
                if (_page > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: globalIndex < 0
                        ? null
                        : () => study.toggleMemorized(globalIndex),
                    icon: Icon(mastered ? Icons.check : Icons.bookmark_add_outlined),
                    label: Text(mastered ? '已掌握' : '标记掌握'),
                  ),
                ),
                if (_page < cards.length - 1) const SizedBox(width: 12),
                if (_page < cards.length - 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('下一张'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 可翻面的知识卡片。
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.card});

  final KnowledgeCard card;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _showBack = !_showBack),
      child: Card(
        elevation: 2,
        shadowColor: scheme.shadow.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: scheme.surface,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final Animation<double> rotate =
                Tween<double>(begin: 0.35, end: 1.0).animate(animation);
            return FadeTransition(opacity: rotate, child: child);
          },
          child: _showBack
              ? _CardBack(key: const ValueKey<String>('back'), card: widget.card)
              : _CardFront(
                  key: const ValueKey<String>('front'),
                  card: widget.card,
                ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({super.key, required this.card});

  final KnowledgeCard card;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline, size: 32, color: scheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            card.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            card.chapter,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.touch_app, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '点击卡片翻面查看内容',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.card});

  final KnowledgeCard card;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                card.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const Spacer(),
              Icon(Icons.touch_app, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                card.content,
                style: const TextStyle(fontSize: 14, height: 1.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
