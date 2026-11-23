import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/grid_entry.dart';
import 'ai_settings_screen.dart';
import 'import_screen.dart';
import 'memorize_screen.dart';
import 'my_questions_screen.dart';
import 'papers_screen.dart';
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
                childAspectRatio: 1.55,
                children: <Widget>[
                  GridEntry(
                    icon: Icons.assignment_outlined,
                    title: '成套练习',
                    subtitle: '5套内置试卷',
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
