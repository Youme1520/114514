import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_config.dart';
import '../models/study_progress.dart';

/// 本地配置服务：主题、AI 配置、学习统计、背诵进度与断点续传。
class SettingsService {
  SettingsService();

  static const String _keyTheme = 'theme_mode';
  static const String _keyAi = 'ai_config';
  static const String _keyAnswered = 'stat_answered';
  static const String _keyCorrect = 'stat_correct';
  static const String _keyMemorized = 'memorized_cards';
  static const String _keyStudyProgress = 'study_progress';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// 读取主题模式。
  Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await _prefs;
    final String? value = prefs.getString(_keyTheme);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// 保存主题模式。
  Future<void> setThemeMode(ThemeMode mode) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_keyTheme, mode.name);
  }

  /// 读取 AI 配置。
  Future<AiConfig> getAiConfig() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_keyAi);
    if (raw == null || raw.isEmpty) return AiConfig.defaultZhipu;
    return AiConfig.fromJson(raw);
  }

  /// 保存 AI 配置。
  Future<void> setAiConfig(AiConfig config) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_keyAi, _encodeConfig(config));
  }

  /// 累计答题总数。
  Future<int> getAnswered() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getInt(_keyAnswered) ?? 0;
  }

  /// 累计答对（客观题）/自评得分题数。
  Future<int> getCorrect() async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getInt(_keyCorrect) ?? 0;
  }

  /// 记录一次作答结果。
  Future<void> recordAnswer({required bool correct}) async {
    final SharedPreferences prefs = await _prefs;
    final int answered = (prefs.getInt(_keyAnswered) ?? 0) + 1;
    await prefs.setInt(_keyAnswered, answered);
    if (correct) {
      final int correctCount = (prefs.getInt(_keyCorrect) ?? 0) + 1;
      await prefs.setInt(_keyCorrect, correctCount);
    }
  }

  /// 读取已掌握（已翻面）的卡片索引集合。
  Future<Set<int>> getMemorized() async {
    final SharedPreferences prefs = await _prefs;
    final List<String> raw = prefs.getStringList(_keyMemorized) ?? <String>[];
    return raw.map((String e) => int.tryParse(e)).whereType<int>().toSet();
  }

  /// 保存已掌握卡片索引集合。
  Future<void> setMemorized(Set<int> indexes) async {
    final SharedPreferences prefs = await _prefs;
    final List<String> raw =
        indexes.map((int e) => e.toString()).toList()..sort();
    await prefs.setStringList(_keyMemorized, raw);
  }

  /// 读取断点续传进度（无进度返回 null）。
  Future<StudyProgress?> getStudyProgress() async {
    final SharedPreferences prefs = await _prefs;
    return StudyProgress.fromJsonString(prefs.getString(_keyStudyProgress));
  }

  /// 保存断点续传进度。
  Future<void> setStudyProgress(StudyProgress progress) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_keyStudyProgress, progress.toJsonString());
  }

  /// 清除断点续传进度。
  Future<void> clearStudyProgress() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(_keyStudyProgress);
  }

  /// 将配置编码为 JSON 字符串（带容错）。
  static String _encodeConfig(AiConfig config) {
    return '{"providerName":"${_escape(config.providerName)}",'
        '"baseUrl":"${_escape(config.baseUrl)}",'
        '"apiKey":"${_escape(config.apiKey)}",'
        '"model":"${_escape(config.model)}"}';
  }

  static String _escape(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }
}
