import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yingxiang_tiku_app/models/question.dart';
import 'package:yingxiang_tiku_app/models/study_progress.dart';
import 'package:yingxiang_tiku_app/providers/settings_provider.dart';
import 'package:yingxiang_tiku_app/services/settings_service.dart';
import 'package:yingxiang_tiku_app/utils/shuffle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyProgress 序列化', () {
    test('toJsonString / fromJsonString 往返', () {
      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.paper,
        title: '第1套 · 整套练习',
        identifier: '1',
        chapter: '',
        currentIndex: 12,
        totalCount: 36,
        randomOrder: true,
        randomSeed: 42,
        updatedAt: 1700000000000,
      );

      final StudyProgress? restored =
          StudyProgress.fromJsonString(progress.toJsonString());
      expect(restored, isNotNull);
      expect(restored!.kind, ProgressKind.paper);
      expect(restored.title, '第1套 · 整套练习');
      expect(restored.identifier, '1');
      expect(restored.currentIndex, 12);
      expect(restored.totalCount, 36);
      expect(restored.randomOrder, isTrue);
      expect(restored.randomSeed, 42);
      expect(restored.updatedAt, 1700000000000);
      expect(restored.isValid, isTrue);
    });

    test('fromJsonString 对 null / 空 / 非法输入返回 null', () {
      expect(StudyProgress.fromJsonString(null), isNull);
      expect(StudyProgress.fromJsonString(''), isNull);
      expect(StudyProgress.fromJsonString('not-json'), isNull);
    });

    test('缺省字段使用默认值', () {
      final StudyProgress? restored =
          StudyProgress.fromJsonString('{"kind":"type","identifier":"单选"}');
      expect(restored, isNotNull);
      expect(restored!.title, '');
      expect(restored.currentIndex, 0);
      expect(restored.totalCount, 0);
      expect(restored.randomOrder, isFalse);
      expect(restored.randomSeed, 0);
    });
  });

  group('SettingsService 断点续传存储/恢复', () {
    test('保存 -> 读取 -> 清除', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SettingsService service = SettingsService();

      expect(await service.getStudyProgress(), isNull);

      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.memorize,
        title: 'DR检查原则',
        identifier: 'DR检查原则',
        chapter: 'DR检查原则',
        currentIndex: 5,
        totalCount: 10,
      );
      await service.setStudyProgress(progress);

      final StudyProgress? loaded = await service.getStudyProgress();
      expect(loaded, isNotNull);
      expect(loaded!.kind, ProgressKind.memorize);
      expect(loaded.identifier, 'DR检查原则');
      expect(loaded.currentIndex, 5);

      await service.clearStudyProgress();
      expect(await service.getStudyProgress(), isNull);
    });
  });

  group('seededShuffle 确定性洗牌', () {
    test('相同种子得到相同顺序', () {
      final List<int> input = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final List<int> a = seededShuffle(input, 42);
      final List<int> b = seededShuffle(input, 42);
      expect(a, b);
    });

    test('不同种子通常得到不同顺序', () {
      final List<int> input = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final List<int> a = seededShuffle(input, 1);
      final List<int> b = seededShuffle(input, 2);
      expect(a, isNot(equals(b)));
    });

    test('洗牌不丢元素且不重复', () {
      final List<int> input = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      final List<int> shuffled = seededShuffle(input, 7);
      expect(shuffled.toSet(), input.toSet());
      expect(shuffled.length, input.length);
    });
  });

  group('SettingsProvider 断点续传状态', () {
    test('init 读取 -> save 更新 -> clear 清除', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SettingsProvider provider = SettingsProvider(SettingsService());

      await provider.init();
      expect(provider.studyProgress, isNull);

      final StudyProgress progress = StudyProgress(
        kind: ProgressKind.type,
        title: '单选 · 专项练习',
        identifier: QuestionType.single,
        currentIndex: 3,
        totalCount: 100,
      );
      await provider.saveStudyProgress(progress);
      expect(provider.studyProgress?.identifier, QuestionType.single);
      expect(provider.studyProgress?.currentIndex, 3);

      await provider.clearStudyProgress();
      expect(provider.studyProgress, isNull);
    });
  });
}
