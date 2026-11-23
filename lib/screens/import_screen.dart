import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/import_template.dart';
import '../providers/study_provider.dart';
import '../services/import_service.dart';
import '../widgets/common.dart';

/// 题库导入页：格式说明 + 文件选择导入。
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _importing = false;

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    final StudyProvider study = context.read<StudyProvider>();
    final ImportResult result = await study.importFromFile();
    if (!mounted) return;
    setState(() => _importing = false);

    final String message;
    if (result.hasError) {
      message = result.error!;
    } else if (result.questions.isEmpty) {
      message = '未解析到有效题目，请检查文件格式';
    } else {
      final int inserted = result.questions.length - result.duplicates;
      message = '导入完成：成功 $inserted 题，去重 ${result.duplicates}，'
          '跳过 ${result.skipped}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('题库导入')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _ExpandSection(title: '支持字段', child: Text(importFieldDescription)),
          _ExpandSection(
            title: 'JSON 示例',
            child: SelectableText(
              importJsonExample,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          _ExpandSection(
            title: 'CSV 示例',
            child: SelectableText(
              importCsvExample,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            importTips,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _importing ? null : _import,
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_upload_outlined),
            label: Text(_importing ? '导入中…' : '选择文件导入'),
          ),
        ],
      ),
    );
  }
}

class _ExpandSection extends StatelessWidget {
  const _ExpandSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );
  }
}
