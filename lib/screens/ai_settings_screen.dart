import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_config.dart';
import '../providers/settings_provider.dart';

/// AI 助手配置页：OpenAI 兼容接口的 Base URL、API Key 与模型名。
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _modelController;
  String _providerName = '';

  @override
  void initState() {
    super.initState();
    final AiConfig config = context.read<SettingsProvider>().aiConfig;
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
    _providerName = config.providerName;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyPreset(AiConfig preset) {
    setState(() {
      _providerName = preset.providerName;
      _baseUrlController.text = preset.baseUrl;
      _modelController.text = preset.model;
    });
  }

  Future<void> _save() async {
    final AiConfig config = AiConfig(
      providerName: _providerName.isEmpty ? '自定义' : _providerName,
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );
    await context.read<SettingsProvider>().updateAiConfig(config);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI 配置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 助手')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            '选择免费接口',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(AiConfig.defaultZhipu),
                  child: const Text('智谱 GLM-4-Flash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPreset(AiConfig.siliconFlow),
                  child: const Text('硅基流动 Qwen3-8B'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '接口配置',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://open.bigmodel.cn/api/paas/v4/',
              helperText: 'OpenAI 兼容接口根地址（不含 /chat/completions）',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型名',
              hintText: 'glm-4-flash',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: '填入你自己的 Key',
              helperText: 'Key 仅保存在本机',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存配置'),
          ),
          const SizedBox(height: 16),
          Text(
            '说明：本应用采用 OpenAI 兼容的 /chat/completions 接口，提供深度解析与主观题智能批改。'
            '上述两个接口均提供免费额度，需前往对应平台注册并填写自己的 API Key。'
            'API Key 通过 shared_preferences 保存在本机，不会上传。',
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
