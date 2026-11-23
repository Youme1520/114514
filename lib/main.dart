import 'package:flutter/material.dart';

import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SettingsService settingsService = SettingsService();
  final SettingsProvider settingsProvider = SettingsProvider(settingsService);
  final StudyProvider studyProvider = StudyProvider(
    db: DatabaseService.instance,
    settings: settingsService,
  );

  // 预加载本地配置、导入题库与背诵进度。
  await settingsProvider.init();
  await studyProvider.init();

  runApp(
    YingxiangTikuApp(
      settingsProvider: settingsProvider,
      studyProvider: studyProvider,
    ),
  );
}
