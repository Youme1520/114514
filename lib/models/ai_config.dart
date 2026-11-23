import 'dart:convert';

/// AI 接口配置模型。
///
/// 使用 OpenAI 兼容的 /chat/completions 接口，[baseUrl] 保存接口根地址
/// （不含 chat/completions），例如 https://api.siliconflow.cn/v1/。
class AiConfig {
  const AiConfig({
    this.providerName = '智谱 GLM-4-Flash（默认）',
    this.baseUrl = 'https://open.bigmodel.cn/api/paas/v4/',
    this.apiKey = '',
    this.model = 'glm-4-flash',
  });

  /// 服务商显示名。
  final String providerName;

  /// 接口根地址（末尾可带或不带斜杠）。
  final String baseUrl;

  /// API Key。
  final String apiKey;

  /// 模型名。
  final String model;

  bool get hasKey => apiKey.trim().isNotEmpty;

  /// 默认配置（智谱 GLM-4-Flash，免费接口需用户填 key）。
  static const AiConfig defaultZhipu = AiConfig(
    providerName: '智谱 GLM-4-Flash（默认）',
    baseUrl: 'https://open.bigmodel.cn/api/paas/v4/',
    apiKey: '',
    model: 'glm-4-flash',
  );

  /// 硅基流动默认配置。
  static const AiConfig siliconFlow = AiConfig(
    providerName: '硅基流动 Qwen3-8B',
    baseUrl: 'https://api.siliconflow.cn/v1/',
    apiKey: '',
    model: 'Qwen/Qwen3-8B',
  );

  /// 序列化为 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
        'providerName': providerName,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
      };

  /// 从 JSON 构造。
  factory AiConfig.fromJson(String source) {
    try {
      final Map<String, dynamic> map =
          jsonDecode(source) as Map<String, dynamic>;
      return AiConfig(
        providerName: (map['providerName'] as String?) ?? defaultZhipu.providerName,
        baseUrl: (map['baseUrl'] as String?) ?? defaultZhipu.baseUrl,
        apiKey: (map['apiKey'] as String?) ?? '',
        model: (map['model'] as String?) ?? defaultZhipu.model,
      );
    } catch (_) {
      return defaultZhipu;
    }
  }

  AiConfig copyWith({
    String? providerName,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    return AiConfig(
      providerName: providerName ?? this.providerName,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }
}
