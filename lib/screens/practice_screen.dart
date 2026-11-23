import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_config.dart';
import '../models/question.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/option_tile.dart';
import 'result_screen.dart';

/// 练习页：逐题作答，支持客观题自动判分与主观题自评/AI 批改。
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.title,
    required this.questions,
  });

  final String title;
  final List<Question> questions;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final List<double> _earned =
      List<double>.filled(widget.questions.length, 0);
  late final List<String> _answers =
      List<String>.filled(widget.questions.length, '');
  late final List<bool> _done = List<bool>.filled(widget.questions.length, false);

  int _index = 0;
  bool _showAnswer = false;
  bool _aiLoading = false;
  double? _aiScore;
  String? _aiFeedback;
  final TextEditingController _controller = TextEditingController();

  Question get _q => widget.questions[_index];

  bool get _answered => _done[_index];

  int get _answeredCount => _done.where((bool e) => e).length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goTo(int index) {
    setState(() {
      _index = index;
      _showAnswer = false;
      _aiScore = null;
      _aiFeedback = null;
      _controller.text = _answers[index];
    });
  }

  void _selectOption(int i) {
    if (_answered) return;
    final String letter = optionLetter(i);
    final bool correct = letter == _q.answer.trim().toUpperCase();
    setState(() {
      _answers[_index] = letter;
      _done[_index] = true;
      _earned[_index] = correct ? _q.score : 0;
    });
    context.read<SettingsProvider>().recordAnswer(correct: correct);
  }

  void _revealAnswer() {
    setState(() => _showAnswer = true);
  }

  void _selfGrade(double fraction) {
    final double earned = _q.score * fraction;
    setState(() {
      _answers[_index] = _controller.text.trim();
      _done[_index] = true;
      _earned[_index] = earned;
    });
    context.read<SettingsProvider>().recordAnswer(correct: fraction >= 1.0);
  }

  Future<void> _aiGrade() async {
    final AiConfig ai = context.read<SettingsProvider>().aiConfig;
    if (!ai.hasKey) {
      _toast('请先在「AI 助手」配置 API Key');
      return;
    }
    setState(() => _aiLoading = true);
    try {
      final GradeResult result = await AiService().gradeSubjective(
        ai,
        _q,
        _controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _answers[_index] = _controller.text.trim();
        _done[_index] = true;
        _earned[_index] = result.score;
        _aiScore = result.score;
        _aiFeedback = result.feedback;
        _showAnswer = true;
      });
      context
          .read<SettingsProvider>()
          .recordAnswer(correct: result.score >= _q.score * 0.6);
    } catch (e) {
      if (mounted) _toast('AI 批改失败：$e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _analyzeCurrent() async {
    final AiConfig ai = context.read<SettingsProvider>().aiConfig;
    if (!ai.hasKey) {
      _toast('请先在「AI 助手」配置 API Key');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AiAnalyzeSheet(question: _q, config: ai),
    );
  }

  void _next() {
    if (_index < widget.questions.length - 1) {
      _goTo(_index + 1);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            title: widget.title,
            questions: widget.questions,
            answers: _answers,
            earned: _earned,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress = widget.questions.isEmpty
        ? 0
        : _answeredCount / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: 'AI 深度解析',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _analyzeCurrent,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(value: progress, minHeight: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: <Widget>[
                Text(
                  '第 ${_index + 1}/${widget.questions.length} 题',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                TypeBadge(_q.type, compact: true),
                const Spacer(),
                Text(
                  '${formatScore(_q.score)} 分',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_q.groupStem != null && _q.groupStem!.isNotEmpty) ...[
                    _GroupStemCard(text: _q.groupStem!),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _q.stem,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                  const SizedBox(height: 16),
                  if (_q.isObjective) ..._buildObjective(),
                  if (_q.isSubjective) ..._buildSubjective(),
                  const SizedBox(height: 12),
                  ..._buildFeedback(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  List<Widget> _buildObjective() {
    return <Widget>[
      for (int i = 0; i < _q.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OptionTile(
            index: i,
            text: _q.options[i],
            isSelected: _answers[_index] == optionLetter(i),
            isCorrect: optionLetter(i) == _q.answer.trim().toUpperCase(),
            showResult: _answered,
            onTap: _answered ? null : () => _selectOption(i),
          ),
        ),
    ];
  }

  List<Widget> _buildSubjective() {
    return <Widget>[
      TextField(
        controller: _controller,
        enabled: !_answered,
        maxLines: 6,
        minLines: 4,
        decoration: InputDecoration(
          hintText: _answered ? '本题已作答' : '在此输入你的答案…',
          alignLabelWithHint: true,
        ),
        onChanged: _answered
            ? null
            : (String v) {
                if (!_answered) _answers[_index] = v.trim();
              },
      ),
    ];
  }

  List<Widget> _buildFeedback() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (_q.isObjective && _answered) {
      final bool correct = _earned[_index] >= _q.score;
      final Color color = correct ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
      final String correctText = _correctOptionText();
      return <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    correct ? Icons.check_circle : Icons.cancel,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    correct ? '回答正确' : '回答错误',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '正确答案：${_q.answer.trim()}${correctText.isEmpty ? '' : '. $correctText'}',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              if (_q.analysis.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '解析：${_q.analysis}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    if (_q.isSubjective) {
      final List<Widget> children = <Widget>[];
      if (_aiScore != null) {
        children.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'AI 评分：${formatScore(_aiScore!)} / ${formatScore(_q.score)} 分',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (_aiFeedback != null && _aiFeedback!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _aiFeedback!,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      if (_showAnswer) {
        children.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.primary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '参考答案',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _q.answer,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
                if (_q.analysis.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '评分要点：${_q.analysis}',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }
      return children;
    }
    return const <Widget>[];
  }

  Widget _buildBottomBar() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (_q.isObjective) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: <Widget>[
            if (_index > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goTo(_index - 1),
                  child: const Text('上一题'),
                ),
              ),
            if (_index > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _answered
                  ? FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index == widget.questions.length - 1
                            ? '查看结果'
                            : '下一题',
                      ),
                    )
                  : FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surfaceVariant,
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      child: const Text('请选择答案'),
                    ),
            ),
          ],
        ),
      );
    }

    // 主观题。
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!_answered)
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _aiLoading ? null : _aiGrade,
                    icon: _aiLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('AI 批改'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _revealAnswer,
                    child: const Text('显示参考答案'),
                  ),
                ),
              ],
            ),
          if (!_answered && _showAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _selfGrade(1.0),
                      child: const Text('完全正确'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _selfGrade(0.5),
                      child: const Text('部分正确'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _selfGrade(0),
                      child: const Text('错误'),
                    ),
                  ),
                ],
              ),
            ),
          if (_answered)
            Row(
              children: <Widget>[
                if (_index > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _goTo(_index - 1),
                      child: const Text('上一题'),
                    ),
                  ),
                if (_index > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(
                      _index == widget.questions.length - 1
                          ? '查看结果'
                          : '下一题',
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _correctOptionText() {
    final String answer = _q.answer.trim().toUpperCase();
    if (answer.isEmpty) return '';
    final int idx = answer.codeUnitAt(0) - 65;
    if (idx < 0 || idx >= _q.options.length) return '';
    return _q.options[idx];
  }
}

class _GroupStemCard extends StatelessWidget {
  const _GroupStemCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.subject, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI 深度解析底部弹窗。
class _AiAnalyzeSheet extends StatefulWidget {
  const _AiAnalyzeSheet({required this.question, required this.config});

  final Question question;
  final AiConfig config;

  @override
  State<_AiAnalyzeSheet> createState() => _AiAnalyzeSheetState();
}

class _AiAnalyzeSheetState extends State<_AiAnalyzeSheet> {
  String? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final String text =
          await AiService().analyzeQuestion(widget.config, widget.question);
      if (!mounted) return;
      setState(() {
        _result = text;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'AI 深度解析',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Text(_error!, style: const TextStyle(color: Colors.red))
                      : SingleChildScrollView(
                          child: SelectableText(
                            _result ?? '（无内容）',
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
