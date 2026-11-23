import 'package:flutter/material.dart';

import '../models/ai_config.dart';
import '../services/settings_service.dart';

/// 设置状态：主题模式、AI 配置与学习统计。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._service);

  final SettingsService _service;

  ThemeMode _themeMode = ThemeMode.light;
  AiConfig _aiConfig = AiConfig.defaultZhipu;
  int _totalAnswered = 0;
  int _correctCount = 0;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;

  AiConfig get aiConfig => _aiConfig;

  int get totalAnswered => _totalAnswered;

  int get correctCount => _correctCount;

  bool get isDark => _themeMode == ThemeMode.dark;

  /// 加载本地配置与统计。
  Future<void> init() async {
    if (_loaded) return;
    _themeMode = await _service.getThemeMode();
    _aiConfig = await _service.getAiConfig();
    _totalAnswered = await _service.getAnswered();
    _correctCount = await _service.getCorrect();
    _loaded = true;
    notifyListeners();
  }

  /// 设置主题模式并持久化。
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _service.setThemeMode(mode);
  }

  /// 切换明暗主题。
  Future<void> toggleTheme() async {
    await setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  /// 更新 AI 配置并持久化。
  Future<void> updateAiConfig(AiConfig config) async {
    _aiConfig = config;
    notifyListeners();
    await _service.setAiConfig(config);
  }

  /// 应用内置预设配置。
  Future<void> applyPreset(AiConfig preset) async {
    await updateAiConfig(preset);
  }

  /// 记录一次作答结果。
  Future<void> recordAnswer({required bool correct}) async {
    _totalAnswered++;
    if (correct) _correctCount++;
    notifyListeners();
    await _service.recordAnswer(correct: correct);
  }
}
