import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';
import 'ai_settings_screen.dart';
import 'import_screen.dart';
import 'my_questions_screen.dart';

/// 我的页：主题切换、AI 配置、题库导入、学习统计与关于。
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Consumer2<SettingsProvider, StudyProvider>(
        builder: (
          BuildContext context,
          SettingsProvider settings,
          StudyProvider study,
          Widget? _,
        ) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: settings.isDark,
                  onChanged: (_) => settings.toggleTheme(),
                  secondary: Icon(
                    settings.isDark ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: const Text('暗黑模式'),
                  subtitle: const Text('全界面暗色主题适配'),
                ),
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.auto_awesome,
                title: 'AI 助手',
                subtitle: '深度解析 · 主观题批改',
                onTap: () => _push(context, const AiSettingsScreen()),
              ),
              _MenuCard(
                icon: Icons.file_upload_outlined,
                title: '题库导入',
                subtitle: 'JSON / CSV 导入自定义题库',
                onTap: () => _push(context, const ImportScreen()),
              ),
              _MenuCard(
                icon: Icons.folder_outlined,
                title: '我的题库',
                subtitle: '导入题目管理（${study.importedQuestions.length} 题）',
                onTap: () => _push(context, const MyQuestionsScreen()),
              ),
              const SizedBox(height: 12),
              const SectionTitle('学习统计'),
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      _StatItem(label: '已答题', value: '${settings.totalAnswered}'),
                      _StatItem(label: '答对题', value: '${settings.correctCount}'),
                      _StatItem(label: '已背卡片', value: '${study.memorizedCount}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SectionTitle('关于'),
              Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '影像技术刷题宝',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '医学影像技术备考刷题与背诵工具。\n'
                        '内置 10 套试卷（新版 180 题 + 旧版 135 题）与 25 个章节知识卡片，'
                        '支持填空题、JSON/CSV 导入与 AI 深度解析、主观题批改。\n版本 1.1.0',
                        style: TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
