/// 通用格式化工具函数。

/// 将分数格式化为字符串：整数不显示小数，非整数保留一位小数。
String formatScore(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(1);
}
