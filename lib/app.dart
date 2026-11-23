import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'providers/settings_provider.dart';
import 'providers/study_provider.dart';
import 'screens/main_shell.dart';
import 'theme.dart';

/// 应用根组件。
class YingxiangTikuApp extends StatelessWidget {
  const YingxiangTikuApp({
    super.key,
    required this.settingsProvider,
    required this.studyProvider,
  });

  final SettingsProvider settingsProvider;
  final StudyProvider studyProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<StudyProvider>.value(value: studyProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (BuildContext context, SettingsProvider settings, _) {
          return MaterialApp(
            title: '影像技术刷题宝',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: settings.themeMode,
            home: const MainShell(),
          );
        },
      ),
    );
  }
}
