import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../models/study_progress.dart';
import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/grid_entry.dart';
import 'ai_settings_screen.dart';
import 'card_study_screen.dart';
import 'chapter_practice_screen.dart';
import 'import_screen.dart';
import 'memorize_screen.dart';
import 'my_questions_screen.dart';
import 'papers_screen.dart';
import 'practice_screen.dart';
import 'type_practice_screen.dart';

/// 首页 Dashboard：进度条 + 宫格入口。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('影像技术刷题宝'),
        actions: <Widget>[
          Consumer<SettingsProvider>(
            builder: (BuildContext context, SettingsProvider s, _) {
              return IconButton(
                tooltip: s.isDark ? '切换为亮色' : '切换为暗色',
                icon: Icon(s.isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => s.toggleTheme(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer2<SettingsProvider, StudyProvider>(
        builder: (
          BuildContext context,
          SettingsProvider settings,
          StudyProvider study,
          Widget? _,
        ) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              _ProgressCard(settings: settings, study: study),
              if (settings.studyProgress != null) ...[
                const SizedBox(height: 16),
                _ResumeCard(
                  progress: settings.studyProgress!,
                  onTap: () => _resume(
                    context,
                    settings,
                    study,
                    settings.studyProgress!,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                '功能入口',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: <Widget>[
                  GridEntry(
                    icon: Icons.assignment_outlined,
                    title: '成套练习',
                    subtitle: '10套内置试卷',
                    color: const Color(0xFF4CAF50),
                    onTap: () => _push(context, const PapersScreen()),
                  ),
                  GridEntry(
                    icon: Icons.category_outlined,
                    title: '分题型刷题',
                    subtitle: '单选·名词解释等',
                    color: const Color(0xFF2196F3),
                    onTap: () => _push(context, const TypePracticeScreen()),
                  ),
                  GridEntry(
                    icon: Icons.menu_book_outlined,
                    title: '分章节刷题',
                    subtitle: '十章习题精练',
                    color: const Color(0xFF673AB7),
                    onTap: () => _push(context, const ChapterPracticeScreen()),
                  ),
                  GridEntry(
                    icon: Icons.style_outlined,
                    title: '分章节背诵',
                    subtitle: '知识卡片翻卡',
                    color: const Color(0xFF009688),
                    onTap: () => _push(context, const MemorizeScreen()),
                  ),
                  GridEntry(
                    icon: Icons.file_upload_outlined,
                    title: '题库导入',
                    subtitle: 'JSON / CSV',
                    color: const Color(0xFFFF9800),
                    onTap: () => _push(context, const ImportScreen()),
                  ),
                  GridEntry(
                    icon: Icons.auto_awesome,
                    title: 'AI 助手',
                    subtitle: '深度解析·批改',
                    color: const Color(0xFF9C27B0),
                    onTap: () => _push(context, const AiSettingsScreen()),
                  ),
                  GridEntry(
                    icon: Icons.folder_outlined,
                    title: '我的题库',
                    subtitle: '导入题管理',
                    color: const Color(0xFF607D8B),
                    onTap: () => _push(context, const MyQuestionsScreen()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  /// 处理「继续上次刷题」：弹窗确认后跳转到对应进度。
  Future<void> _resume(
    BuildContext context,
    SettingsProvider settings,
    StudyProvider study,
    StudyProgress progress,
  ) async {
    final String unit =
        progress.kind == ProgressKind.memorize ? '张' : '题';
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('继续上次刷题'),
        content: Text(
          '是否继续上次进度？\n${progress.title}\n'
          '第 ${progress.currentIndex + 1}/${progress.totalCount} $unit',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('放弃'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('继续'),
          ),
        ],
      ),
    );

    if (ok != true) {
      await settings.clearStudyProgress();
      return;
    }

    if (!context.mounted) return;

    if (progress.kind == ProgressKind.memorize) {
      final chapter = study.chapterByName(progress.identifier);
      if (chapter == null) {
        await settings.clearStudyProgress();
        return;
      }
      _push(
        context,
        CardStudyScreen(
          chapter: chapter,
          initialPage: progress.currentIndex
              .clamp(0, chapter.cards.isEmpty ? 0 : chapter.cards.length - 1)
              .toInt(),
        ),
      );
      return;
    }

    final List<Question> questions = study.resumeQuestionsFor(progress);
    if (questions.isEmpty) {
      await settings.clearStudyProgress();
      return;
    }
    _push(
      context,
      PracticeScreen(
        title: progress.title,
        questions: questions,
        resumeKind: progress.kind,
        resumeIdentifier: progress.identifier,
        initialIndex: progress.currentIndex
            .clamp(0, questions.length - 1)
            .toInt(),
        randomOrder: progress.randomOrder,
        randomSeed: progress.randomSeed,
      ),
    );
  }
}

/// 顶部学习进度卡片。
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.settings, required this.study});

  final SettingsProvider settings;
  final StudyProvider study;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double quizProgress = study.totalQuestions == 0
        ? 0
        : (settings.totalAnswered / study.totalQuestions).clamp(0.0, 1.0);
    final double memorizeProgress = study.totalCards == 0
        ? 0
        : (study.memorizedCount / study.totalCards).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.school, color: scheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  '学习进度',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProgressRow(
              label: '刷题进度',
              value: quizProgress,
              detail: '${settings.totalAnswered}/${study.totalQuestions} 题',
            ),
            const SizedBox(height: 14),
            _ProgressRow(
              label: '背诵进度',
              value: memorizeProgress,
              detail: '${study.memorizedCount}/${study.totalCards} 卡',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              detail,
              style: TextStyle(
                color: scheme.onPrimary.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: scheme.onPrimary.withOpacity(0.25),
            valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

/// 「继续上次刷题」快捷入口卡片。
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.progress, required this.onTap});

  final StudyProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String unit = progress.kind == ProgressKind.memorize ? '张' : '题';
    final String position = progress.totalCount > 0
        ? '第 ${progress.currentIndex + 1}/${progress.totalCount} $unit'
        : '';
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withOpacity(0.5)),
      ),
      color: scheme.primary.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(Icons.play_circle_outline, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '继续上次刷题',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (position.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  position,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
