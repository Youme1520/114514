import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/ai_config.dart';
import '../models/question.dart';

/// 主观题批改结果。
class GradeResult {
  const GradeResult({required this.score, required this.feedback});

  /// 得分（0～题目满分）。
  final double score;

  /// 评语/反馈。
  final String feedback;
}

/// AI 服务：接入 OpenAI 兼容的 /chat/completions 接口。
///
/// 功能：① 题目深度解析；② 主观题智能批改评分。
class AiService {
  AiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 20),
        contentType: Headers.jsonContentType,
      ),
    );
  }

  late final Dio _dio;

  /// 拼接完整的 chat/completions 地址。
  String buildEndpoint(AiConfig config) {
    String base = config.baseUrl.trim();
    if (base.isEmpty) base = AiConfig.defaultZhipu.baseUrl;
    if (!base.endsWith('/')) base = '$base/';
    return '${base}chat/completions';
  }

  /// 校验配置是否可用。
  String? validate(AiConfig config) {
    if (config.baseUrl.trim().isEmpty) return '请填写 Base URL';
    if (config.model.trim().isEmpty) return '请填写模型名';
    if (!config.hasKey) return '请填写 API Key';
    return null;
  }

  /// 深度解析题目：题干、选项、考点与解析。
  Future<String> analyzeQuestion(AiConfig config, Question question) async {
    final String? error = validate(config);
    if (error != null) {
      throw Exception(error);
    }
    final StringBuffer prompt = StringBuffer();
    prompt.writeln('你是一名医学影像技术考试辅导专家。请对下面这道题做深度解析，');
    prompt.writeln('用中文、分点输出：①考点定位 ②题干解析 ③选项/答案分析 ④易错点与记忆技巧。');
    prompt.writeln('题型：${question.type}');
    prompt.writeln('分值：${question.score}分');
    if (question.groupStem != null && question.groupStem!.isNotEmpty) {
      prompt.writeln('材料：${question.groupStem}');
    }
    prompt.writeln('题干：${question.stem}');
    if (question.options.isNotEmpty) {
      prompt.writeln('选项：');
      for (int i = 0; i < question.options.length; i++) {
        prompt.writeln('${_letter(i)}. ${question.options[i]}');
      }
    }
    prompt.writeln('参考答案：${question.answer}');
    if (question.analysis.isNotEmpty) {
      prompt.writeln('参考解析：${question.analysis}');
    }

    return _chat(config, <Map<String, String>>[
      <String, String>{
        'role': 'system',
        'content': '你是专业的医学影像技术辅导老师，回答严谨、条理清晰。',
      },
      <String, String>{'role': 'user', 'content': prompt.toString()},
    ]);
  }

  /// 智能批改主观题，返回 0～满分 的得分与评语。
  Future<GradeResult> gradeSubjective(
    AiConfig config,
    Question question,
    String userAnswer,
  ) async {
    final String? error = validate(config);
    if (error != null) {
      throw Exception(error);
    }
    final String fullScore = _fmtScore(question.score);
    final String prompt = '''
你是医学影像技术阅卷老师，请对下面主观题作答进行批改。
题目（${question.type}，满分${fullScore}分）：${question.stem}
参考答案：${question.answer}
考生作答：${userAnswer.isEmpty ? '（未作答）' : userAnswer}
请严格按要点给分，并输出 JSON（不要输出多余文字），格式：
{"score": 数字（0到${fullScore}），"comment": "简要评语与失分点"}
''';

    final String content = await _chat(config, <Map<String, String>>[
      <String, String>{
        'role': 'system',
        'content': '你是严谨的医学影像技术阅卷老师，只输出要求的 JSON。',
      },
      <String, String>{'role': 'user', 'content': prompt},
    ]);
    return parseGrade(content, question.score);
  }

  /// 调用 chat/completions 并返回文本内容。
  Future<String> _chat(AiConfig config, List<Map<String, String>> messages) async {
    final String url = buildEndpoint(config);
    final Response<dynamic> response = await _dio.post<dynamic>(
      url,
      data: <String, dynamic>{
        'model': config.model.trim(),
        'messages': messages,
        'temperature': 0.3,
        'stream': false,
      },
      options: Options(
        headers: <String, String>{
          'Authorization': 'Bearer ${config.apiKey.trim()}',
        },
      ),
    );

    final dynamic data = response.data;
    if (data is! Map) {
      throw Exception('AI 返回格式异常');
    }
    final List<dynamic>? choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('AI 未返回有效内容');
    }
    final dynamic message = (choices.first as Map)['message'];
    if (message is Map && message['content'] != null) {
      return message['content'].toString();
    }
    throw Exception('AI 返回内容为空');
  }

  /// 从模型输出中解析得分与评语。
  ///
  /// 优先提取 JSON 块；当 JSON 解析失败、缺少 score 字段或不存在 JSON 块时，
  /// 回退到正则匹配 "score：数字" / "得分：数字"。
  GradeResult parseGrade(String content, double fullScore) {
    double score = 0;
    String comment = content.trim();

    final RegExp jsonReg = RegExp(r'\{[\s\S]*\}');
    final Match? match = jsonReg.firstMatch(content);
    bool jsonParsed = false;
    if (match != null) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(match.group(0)!) as Map<String, dynamic>;
        final double? s = _toDouble(map['score']);
        if (s != null) {
          score = s;
          jsonParsed = true;
        }
        if (map['comment'] != null) comment = map['comment'].toString();
      } catch (_) {
        // 回退到正则解析。
      }
    }

    if (!jsonParsed) {
      // 匹配 "score": 数字、score：数字 或 "得分：数字"。
      final RegExp scoreReg = RegExp(
        r'(score|得分)\s*[:：]?\s*"?(\d+(?:\.\d+)?)',
      );
      final Match? sm = scoreReg.firstMatch(content);
      if (sm != null) {
        score = double.tryParse(sm.group(2)!) ?? 0;
      }
    }

    if (score < 0) score = 0;
    if (score > fullScore) score = fullScore;
    return GradeResult(score: score, feedback: comment);
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  String _letter(int index) => String.fromCharCode(65 + index);

  String _fmtScore(double score) {
    return score == score.roundToDouble()
        ? score.toInt().toString()
        : score.toStringAsFixed(1);
  }
}
