/// 题库导入格式说明与示例（JSON / CSV）。
///
/// 字段说明：type/题型、stem/题干、options/选项、answer/答案、analysis/解析、
/// chapter/章节，可选 paperSet/套次、score/分值。
library;

const String importFieldDescription = '''
支持字段（中英文均可，大小写不敏感）：
· type / 题型：单选、共用题干选择、填空、名词解释、简答、分析题
· stem / 题干：题目内容（必填）
· options / 选项：客观题选项，支持 JSON 数组或 "A.xx|B.xx|C.xx|D.xx" 格式
· answer / 答案：选择题为字母（A/B/C/D），填空题为「；」分隔的多个空位答案，主观题为参考答案全文
· analysis / 解析：解析或评分要点（可选）
· chapter / 章节：所属章节（可选）
· paperSet / 套次：试卷套次（可选，默认 0）
· score / 分值：题目分值（可选，默认 0）
· groupStem / 共用题干：共用题干选择题的材料（可选）
''';

const String importJsonExample = '''
[
  {
    "type": "单选",
    "stem": "水的CT值是多少HU？",
    "options": ["-1000", "0", "100", "1000"],
    "answer": "B",
    "analysis": "水的CT值为0 HU。",
    "chapter": "影像技术基础",
    "score": 2
  },
  {
    "type": "名词解释",
    "stem": "CT值",
    "answer": "CT值是重建图像中像素对X线吸收系数的换算值，单位为HU。",
    "analysis": "要点：定义、单位。",
    "score": 3
  }
]
''';

const String importCsvExample = '''type,stem,options,answer,analysis,chapter,score
单选,水的CT值是多少HU？,-1000|0|100|1000,B,水的CT值为0 HU。,影像技术基础,2
名词解释,CT值,,CT值是像素对X线吸收系数的换算值，单位为HU。,要点：定义与单位,影像技术基础,3
''';

const String importTips = '''
导入规则：
1. 支持 .json / .txt（内容为 JSON 数组）与 .csv 文件。
2. CSV 首行为表头，表头字段名见上方说明；选项列可用 JSON 数组或用 |、换行分隔。
3. 导入时自动去重（题干+题型完全相同视为重复）并跳过缺题干的无效行。
4. 导入的题目在"分题型刷题"与"我的题库"中可见。
''';
