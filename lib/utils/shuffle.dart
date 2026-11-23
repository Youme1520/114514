import 'dart:math';

/// 使用给定种子对列表进行确定性的 Fisher-Yates 洗牌。
///
/// 相同输入与相同种子会得到相同顺序，用于「随机顺序」模式的断点续传恢复。
List<T> seededShuffle<T>(List<T> input, int seed) {
  final List<T> list = List<T>.from(input);
  final Random random = Random(seed);
  for (int i = list.length - 1; i > 0; i--) {
    final int j = random.nextInt(i + 1);
    final T tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
  return list;
}
