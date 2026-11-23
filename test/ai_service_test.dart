import 'package:flutter_test/flutter_test.dart';

import 'package:yingxiang_tiku_app/models/ai_config.dart';
import 'package:yingxiang_tiku_app/services/ai_service.dart';

void main() {
  group('buildEndpoint', () {
    test('末尾带斜杠时直接拼接', () {
      final AiConfig config = AiConfig(baseUrl: 'https://x.example/v1/');
      expect(
        AiService().buildEndpoint(config),
        'https://x.example/v1/chat/completions',
      );
    });

    test('末尾不带斜杠时自动补斜杠', () {
      final AiConfig config = AiConfig(baseUrl: 'https://x.example/v1');
      expect(
        AiService().buildEndpoint(config),
        'https://x.example/v1/chat/completions',
      );
    });

    test('空 Base URL 回退到默认智谱地址', () {
      final AiConfig config = AiConfig(baseUrl: '  ');
      expect(
        AiService().buildEndpoint(config),
        'https://open.bigmodel.cn/api/paas/v4/chat/completions',
      );
    });
  });

  group('validate', () {
    test('配置完整时返回 null', () {
      final AiConfig config = AiConfig(
        baseUrl: 'https://x.example/v1/',
        apiKey: 'key',
        model: 'model-a',
      );
      expect(AiService().validate(config), isNull);
    });

    test('缺少 Base URL', () {
      final AiConfig config =
          AiConfig(baseUrl: '', apiKey: 'key', model: 'model-a');
      expect(AiService().validate(config), '请填写 Base URL');
    });

    test('缺少模型名', () {
      final AiConfig config =
          AiConfig(baseUrl: 'https://x', apiKey: 'key', model: '');
      expect(AiService().validate(config), '请填写模型名');
    });

    test('缺少 API Key', () {
      final AiConfig config =
          AiConfig(baseUrl: 'https://x', apiKey: '', model: 'model-a');
      expect(AiService().validate(config), '请填写 API Key');
    });
  });

  group('parseGrade', () {
    test('解析标准 JSON 分数与评语', () {
      final GradeResult r =
          AiService().parseGrade('{"score":8.5,"comment":"答得不错"}', 10);
      expect(r.score, 8.5);
      expect(r.feedback, '答得不错');
    });

    test('score 为字符串数字时也能解析', () {
      final GradeResult r =
          AiService().parseGrade('{"score":"6","comment":"ok"}', 10);
      expect(r.score, 6.0);
      expect(r.feedback, 'ok');
    });

    test('从多余文字中提取 JSON 块', () {
      final GradeResult r =
          AiService().parseGrade('批改结果如下：{"score":7,"comment":"xx"}', 10);
      expect(r.score, 7.0);
      expect(r.feedback, 'xx');
    });

    test('无 JSON 时回退到正则（中文得分）', () {
      final GradeResult r = AiService().parseGrade('得分：8分，要点基本齐全', 10);
      expect(r.score, 8.0);
    });

    test('无 JSON 时回退到正则（英文 score）', () {
      final GradeResult r = AiService().parseGrade('score: 7.5', 10);
      expect(r.score, 7.5);
    });

    test('JSON 存在但非法时回退到正则', () {
      final GradeResult r =
          AiService().parseGrade('得分：9分 {"score": }', 10);
      expect(r.score, 9.0);
    });

    test('JSON 缺少 score 字段时回退到正则', () {
      final GradeResult r = AiService().parseGrade('{"comment":"无分数"} 得分：5', 10);
      expect(r.score, 5.0);
      expect(r.feedback, '无分数');
    });

    test('分数超过满分时被截断', () {
      final GradeResult r =
          AiService().parseGrade('{"score":15,"comment":"x"}', 10);
      expect(r.score, 10.0);
    });

    test('负分数被截断为 0', () {
      final GradeResult r =
          AiService().parseGrade('{"score":-3,"comment":"x"}', 10);
      expect(r.score, 0.0);
    });
  });
}
