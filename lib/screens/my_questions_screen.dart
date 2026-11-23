import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/study_provider.dart';
import '../widgets/common.dart';

/// 我的题库：导入题目列表与管理（删除/清空）。
class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final StudyProvider study = context.read<StudyProvider>();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('清空题库'),
        content: const Text('确定要删除全部导入题目吗？此操作不可撤销。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await study.clearImported();
    }
  }

  @override
  Widget build(BuildContext context) {
    final StudyProvider study = context.watch<StudyProvider>();
    final List<Question> questions = study.importedQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的题库'),
        actions: <Widget>[
          if (questions.isNotEmpty)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: questions.isEmpty
          ? const EmptyView(
              icon: Icons.folder_open,
              message: '暂无导入题目\n可在「题库导入」中导入 JSON/CSV 文件',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (BuildContext context, int i) {
                final Question q = questions[i];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(typeIcon(q.type), color: typeColor(q.type)),
                    title: Text(
                      q.stem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: <Widget>[
                          TypeBadge(q.type, compact: true),
                          if (q.chapter.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                q.chapter,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: q.id == null
                          ? null
                          : () => study.removeImportedQuestion(q.id!),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
