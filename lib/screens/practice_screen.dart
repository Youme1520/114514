import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_config.dart';
import '../models/question.dart';
import '../models/study_progress.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../utils/fill_blank_grader.dart';
import '../utils/format.dart';
import '../utils/shuffle.dart';
import '../widgets/common.dart';
import '../widgets/option_tile.dart';
import 'result_screen.dart';

/// 练习页：逐题作答，支持客观题自动判分、填空题逐空判分与主观题自评/AI 批改。
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.title,
    required this.questions,
    this.resumeKind,
    this.resumeIdentifier,
    this.initialIndex = 0,
    this.randomOrder = false,
    this.randomSeed = 0,
  });

  final String title;
  final List<Question> questions;

  /// 断点续传：进度种类（[ProgressKind.paper] / [ProgressKind.type]）。
  final String? resumeKind;

  /// 断点续传：用于重建题目的标识（套次或题型名）。
  final String? resumeIdentifier;

  /// 初始题号（从 0 开始，用于恢复进度）。
  final int initialIndex;

  /// 是否随机顺序模式。
  final bool randomOrder;

  /// 随机顺序种子。
  final int randomSeed;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late List<Question> _ordered;
  late List<double> _earned;
  late List<String> _answers;
  late List<bool> _done;
  late List<List<TextEditingController>> _fillControllers;

  int _index = 0;
  bool _showAnswer = false;
  bool _aiLoading = false;
  double? _aiScore;
  String? _aiFeedback;
  bool _random = false;
  int _seed = 0;
  final TextEditingController _controller = TextEditingController();

  Question get _q => _ordered[_index];

  bool get _answered => _done[_index];

  int get _answeredCount => _done.where((bool e) => e).length;

  @override
  void initState() {
    super.initState();
    _random = widget.randomOrder;
    _seed = widget.randomSeed == 0
        ? DateTime.now().millisecondsSinceEpoch
        : widget.randomSeed;
    _ordered = _random
        ? seededShuffle(widget.questions, _seed)
        : List<Question>.from(widget.questions);
    _index = widget.initialIndex
        .clamp(0, _ordered.isEmpty ? 0 : _ordered.length - 1)
        .toInt();
    _earned = List<double>.filled(_ordered.length, 0);
    _answers = List<String>.filled(_ordered.length, '');
    _done = List<bool>.filled(_ordered.length, false);
    _fillControllers = <List<TextEditingController>>[
      for (final Question q in _ordered) _buildFillControllers(q),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _disposeFillControllers();
    super.dispose();
  }

  List<TextEditingController> _buildFillControllers(Question q) {
    if (!q.isFillBlank) return const <TextEditingController>[];
    final int n = q.fillBlankAnswers.isEmpty ? 1 : q.fillBlankAnswers.length;
    return List<TextEditingController>.generate(
      n,
      (_) => TextEditingController(),
    );
  }

  void _disposeFillControllers() {
    for (final List<TextEditingController> list in _fillControllers) {
      for (final TextEditingController c in list) {
        c.dispose();
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _ordered.length) return;
    setState(() {
      _index = index;
      _showAnswer = false;
      _aiScore = null;
      _aiFeedback = null;
      _controller.text = _answers[index];
      _syncFillControllersFromAnswer(index);
    });
    _persistProgress();
  }

  void _syncFillControllersFromAnswer(int index) {
    final List<String> blanks = FillBlankGrader.splitBlanks(_answers[index]);
    final List<TextEditingController> ctrls = _fillControllers[index];
    for (int i = 0; i < ctrls.length; i++) {
      ctrls[i].text = i < blanks.length ? blanks[i] : '';
    }
  }

  void _syncFillAnswers() {
    final List<TextEditingController> ctrls = _fillControllers[_index];
    _answers[_index] = ctrls.map((TextEditingController c) => c.text.trim()).join('；');
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
    _persistProgress();
  }

  void _submitFillBlank() {
    if (_answered) return;
    _syncFillAnswers();
    final FillBlankResult result = FillBlankGrader.grade(
      userAnswer: _answers[_index],
      correctAnswer: _q.answer,
      totalScore: _q.score,
    );
    setState(() {
      _done[_index] = true;
      _earned[_index] = result.earnedScore;
      _showAnswer = true;
    });
    context.read<SettingsProvider>().recordAnswer(correct: result.allCorrect);
    _persistProgress();
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
    _persistProgress();
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
      _persistProgress();
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

  void _persistProgress() {
    if (widget.resumeKind == null || widget.resumeIdentifier == null) return;
    context.read<SettingsProvider>().saveStudyProgress(
          StudyProgress(
            kind: widget.resumeKind!,
            title: widget.title,
            identifier: widget.resumeIdentifier!,
            currentIndex: _index,
            totalCount: _ordered.length,
            randomOrder: _random,
            randomSeed: _seed,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  void _clearProgress() {
    if (widget.resumeKind != null) {
      context.read<SettingsProvider>().clearStudyProgress();
    }
  }

  void _next() {
    if (_index < _ordered.length - 1) {
      _goTo(_index + 1);
    } else {
      _clearProgress();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            title: widget.title,
            questions: _ordered,
            answers: _answers,
            earned: _earned,
          ),
        ),
      );
    }
  }

  Future<bool> _confirmOrderChange() async {
    if (_answeredCount == 0) return true;
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('切换顺序'),
        content: const Text('切换顺序将重置当前作答进度，确定继续？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _setOrder(bool random) {
    if (_random == random) return;
    setState(() {
      _random = random;
      _seed = random ? DateTime.now().millisecondsSinceEpoch : 0;
      _ordered = random
          ? seededShuffle(widget.questions, _seed)
          : List<Question>.from(widget.questions);
      _index = 0;
      _earned = List<double>.filled(_ordered.length, 0);
      _answers = List<String>.filled(_ordered.length, '');
      _done = List<bool>.filled(_ordered.length, false);
      _disposeFillControllers();
      _fillControllers = <List<TextEditingController>>[
        for (final Question q in _ordered) _buildFillControllers(q),
      ];
      _controller.clear();
      _showAnswer = false;
      _aiScore = null;
      _aiFeedback = null;
    });
    _persistProgress();
  }

  List<String> _distinctTypes() {
    final List<String> types = <String>[];
    for (final Question q in _ordered) {
      if (!types.contains(q.type)) types.add(q.type);
    }
    return types;
  }

  int _firstIndexOfType(String type) {
    for (int i = 0; i < _ordered.length; i++) {
      if (_ordered[i].type == type) return i;
    }
    return 0;
  }

  void _openAnswerSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter sheetSetState) {
            return _AnswerSheet(
              total: _ordered.length,
              current: _index,
              done: _done,
              types: _distinctTypes(),
              currentType: _q.type,
              random: _random,
              onJump: (int i) {
                Navigator.of(sheetContext).pop();
                _goTo(i);
              },
              onJumpType: (String type) {
                Navigator.of(sheetContext).pop();
                _goTo(_firstIndexOfType(type));
              },
              onToggleOrder: (bool random) async {
                final bool proceed = await _confirmOrderChange();
                if (proceed && mounted) {
                  _setOrder(random);
                }
                sheetSetState(() {});
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_ordered.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const EmptyView(icon: Icons.inbox_outlined, message: '暂无题目'),
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double progress =
        _answeredCount / _ordered.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: '答题卡',
            icon: const Icon(Icons.grid_view_outlined),
            onPressed: _openAnswerSheet,
          ),
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
                  '第 ${_index + 1}/${_ordered.length} 题',
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
                  if (_q.isFillBlank)
                    ..._buildFillBlank()
                  else ...[
                    Text(
                      _q.stem,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    if (_q.isObjective) ..._buildObjective(),
                    if (_q.isSubjective) ..._buildSubjective(),
                  ],
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

  List<Widget> _buildFillBlank() {
    final List<String> blanks = _q.fillBlankAnswers;
    final List<String> segments = _q.stem.split(RegExp(r'_{3,}'));
    final int fields = blanks.isEmpty ? 1 : blanks.length;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < segments.length; i++) {
      if (segments[i].trim().isNotEmpty) {
        children.add(
          Text(segments[i], style: const TextStyle(fontSize: 16, height: 1.7)),
        );
      }
      if (i < fields) {
        children.add(_fillInput(i));
      }
    }
    // 题干空位少于答案数（异常数据兜底）：末尾补齐剩余输入框。
    if (fields > segments.length - 1) {
      for (int i = segments.length; i < fields; i++) {
        children.add(_fillInput(i));
      }
    }
    return children;
  }

  Widget _fillInput(int i) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: _fillControllers[_index][i],
        enabled: !_answered,
        onChanged: _answered ? null : (_) => _syncFillAnswers(),
        decoration: InputDecoration(
          hintText: '第 ${i + 1} 空',
          isDense: true,
        ),
      ),
    );
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

    if (_q.isFillBlank && _answered) {
      final FillBlankResult result = FillBlankGrader.grade(
        userAnswer: _answers[_index],
        correctAnswer: _q.answer,
        totalScore: _q.score,
      );
      final bool allCorrect = result.allCorrect;
      final Color color =
          allCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
      final List<String> correctBlanks = FillBlankGrader.splitBlanks(_q.answer);
      final List<String> userBlanks =
          FillBlankGrader.splitBlanks(_answers[_index]);
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
                  Icon(allCorrect ? Icons.check_circle : Icons.cancel,
                      color: color),
                  const SizedBox(width: 8),
                  Text(
                    '答对 ${result.correctCount}/${result.totalCount} 空',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < correctBlanks.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '空${i + 1}：你的答案「${i < userBlanks.length ? userBlanks[i] : '未填'}」'
                    '  正确答案「${correctBlanks[i]}」',
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
      ];
    }

    if (_q.isObjective && _answered) {
      final bool correct = _earned[_index] >= _q.score;
      final Color color =
          correct ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
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
              border:
                  Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
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

    if (_q.isFillBlank) {
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
                        _index == _ordered.length - 1 ? '查看结果' : '下一题',
                      ),
                    )
                  : FilledButton(
                      onPressed: _submitFillBlank,
                      child: const Text('提交判分'),
                    ),
            ),
          ],
        ),
      );
    }

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
                        _index == _ordered.length - 1 ? '查看结果' : '下一题',
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
                      _index == _ordered.length - 1 ? '查看结果' : '下一题',
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

/// 答题卡底部面板：题目编号跳转 + 题型快速跳转 + 顺序/随机切换。
class _AnswerSheet extends StatelessWidget {
  const _AnswerSheet({
    required this.total,
    required this.current,
    required this.done,
    required this.types,
    required this.currentType,
    required this.random,
    required this.onJump,
    required this.onJumpType,
    required this.onToggleOrder,
  });

  final int total;
  final int current;
  final List<bool> done;
  final List<String> types;
  final String currentType;
  final bool random;
  final void Function(int index) onJump;
  final void Function(String type) onJumpType;
  final void Function(bool random) onToggleOrder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
            Row(
              children: <Widget>[
                const Text(
                  '答题卡',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '顺序/随机',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: random,
                  onChanged: onToggleOrder,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (int i = 0; i < total; i++)
                  _NumberChip(
                    number: i + 1,
                    state: i == current
                        ? _ChipState.current
                        : (done[i] ? _ChipState.done : _ChipState.pending),
                    onTap: () => onJump(i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '跳转题型',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final String type in types)
                  ChoiceChip(
                    label: Text(type),
                    selected: type == currentType,
                    onSelected: (_) => onJumpType(type),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}

enum _ChipState { current, done, pending }

class _NumberChip extends StatelessWidget {
  const _NumberChip({
    required this.number,
    required this.state,
    required this.onTap,
  });

  final int number;
  final _ChipState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Color background = scheme.surfaceVariant;
    Color foreground = scheme.onSurfaceVariant;
    if (state == _ChipState.current) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (state == _ChipState.done) {
      background = const Color(0xFF4CAF50);
      foreground = Colors.white;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
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
