import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

import '../models/question.dart';

/// 导入结果。
class ImportResult {
  const ImportResult({
    this.questions = const <Question>[],
    this.skipped = 0,
    this.duplicates = 0,
    this.error,
  });

  /// 成功解析的题目（未去重）。
  final List<Question> questions;

  /// 因缺题干等原因跳过的行数。
  final int skipped;

  /// 与已有题库重复的题数（由调用方去重后回填）。
  final int duplicates;

  /// 解析错误信息（如文件无法读取/格式非法）。
  final String? error;

  bool get hasError => error != null;

  ImportResult copyWith({int? duplicates}) => ImportResult(
        questions: questions,
        skipped: skipped,
        duplicates: duplicates ?? this.duplicates,
        error: error,
      );
}

/// 题库导入服务：文件选择、JSON/CSV 解析与字段映射。
class ImportService {
  ImportService();

  /// 打开文件选择器并解析所选文件。
  Future<ImportResult> pickAndParse() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return const ImportResult(error: '未选择文件');
      }
      final PlatformFile file = result.files.single;
      final String? name = file.name.toLowerCase();
      if (name == null ||
          !(name.endsWith('.json') ||
              name.endsWith('.txt') ||
              name.endsWith('.csv'))) {
        return const ImportResult(error: '仅支持 .json / .txt / .csv 文件');
      }

      final String content = _readContent(file);
      if (content.trim().isEmpty) {
        return const ImportResult(error: '文件内容为空');
      }
      return parseText(content, name);
    } catch (e) {
      return ImportResult(error: '导入失败：$e');
    }
  }

  /// 根据文件名后缀解析文本内容。
  ImportResult parseText(String content, String fileName) {
    if (fileName.endsWith('.csv')) {
      return _parseCsv(content);
    }
    return _parseJson(content);
  }

  String _readContent(PlatformFile file) {
    final Uint8List? bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return _decodeUtf8(bytes);
    }
    if (file.path != null) {
      final File f = File(file.path!);
      return _decodeUtf8(f.readAsBytesSync());
    }
    return '';
  }

  String _decodeUtf8(Uint8List bytes) {
    // 去除 UTF-8 BOM。
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  ImportResult _parseJson(String content) {
    try {
      final dynamic decoded = jsonDecode(content);
      List<dynamic> list;
      if (decoded is List) {
        list = decoded;
      } else if (decoded is Map<String, dynamic>) {
        final dynamic inner =
            decoded['questions'] ?? decoded['data'] ?? decoded['list'];
        if (inner is List) {
          list = inner;
        } else if (_looksLikeQuestion(decoded)) {
          list = <dynamic>[decoded];
        } else {
          return const ImportResult(error: 'JSON 根节点应为数组或包含 questions/data 字段');
        }
      } else {
        return const ImportResult(error: 'JSON 格式不正确');
      }

      final List<Question> questions = <Question>[];
      int skipped = 0;
      for (final dynamic item in list) {
        if (item is! Map) {
          skipped++;
          continue;
        }
        final Map<String, dynamic> map =
            item.map((dynamic k, dynamic v) => MapEntry(k.toString(), v));
        final Question q = Question.fromJson(map);
        if (q.stem.trim().isEmpty) {
          skipped++;
          continue;
        }
        questions.add(q);
      }
      return ImportResult(questions: questions, skipped: skipped);
    } catch (e) {
      return ImportResult(error: 'JSON 解析失败：$e');
    }
  }

  ImportResult _parseCsv(String content) {
    try {
      final List<List<dynamic>> rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(content);

      if (rows.isEmpty) {
        return const ImportResult(error: 'CSV 内容为空');
      }

      final List<String> headers = rows.first
          .map((dynamic e) => e.toString().trim())
          .toList();
      final Map<String, int> headerIndex = <String, int>{};
      for (int i = 0; i < headers.length; i++) {
        headerIndex[_normalizeHeader(headers[i])] = i;
      }

      final List<Question> questions = <Question>[];
      int skipped = 0;
      for (int r = 1; r < rows.length; r++) {
        final List<dynamic> cells = rows[r];
        final Map<String, dynamic> map = <String, dynamic>{};
        for (int c = 0; c < headers.length && c < cells.length; c++) {
          final String key = _normalizeHeader(headers[c]);
          final String value = cells[c].toString().trim();
          map[_canonicalField(key)] = value;
        }
        final Question q = Question.fromJson(map);
        if (q.stem.trim().isEmpty) {
          skipped++;
          continue;
        }
        questions.add(q);
      }
      return ImportResult(questions: questions, skipped: skipped);
    } catch (e) {
      return ImportResult(error: 'CSV 解析失败：$e');
    }
  }

  /// 表头规范化：转小写、去空白与常见分隔。
  String _normalizeHeader(String header) {
    return header
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_（）()]+'), '')
        .trim();
  }

  /// 判断一个 Map 是否为单道题的 JSON 对象（而非包裹数组的对象）。
  bool _looksLikeQuestion(Map<String, dynamic> map) {
    return map.containsKey('stem') ||
        map.containsKey('题干') ||
        map.containsKey('题目');
  }

  /// 去重键：题型 + 题干（去除首尾空白）。
  static String dedupKey(Question q) => '${q.type}|${q.stem.trim()}';

  /// 按去重键过滤：返回去重后的题目与重复计数。
  static ({List<Question> unique, int duplicates}) deduplicate(
    List<Question> incoming,
    Iterable<Question> existing,
  ) {
    final Set<String> seen = <String>{
      for (final Question q in existing) dedupKey(q),
    };
    final List<Question> unique = <Question>[];
    int duplicates = 0;
    for (final Question q in incoming) {
      final String key = dedupKey(q);
      if (seen.contains(key)) {
        duplicates++;
        continue;
      }
      seen.add(key);
      unique.add(q);
    }
    return (unique: unique, duplicates: duplicates);
  }

  /// 将规范化表头映射为 Question.fromJson 认识的字段名。
  String _canonicalField(String normalized) {
    const Map<String, String> aliases = <String, String>{
      'type': 'type',
      '题型': 'type',
      'stem': 'stem',
      '题干': 'stem',
      '题目': 'stem',
      'options': 'options',
      '选项': 'options',
      'answer': 'answer',
      '答案': 'answer',
      'analysis': 'analysis',
      '解析': 'analysis',
      'chapter': 'chapter',
      '章节': 'chapter',
      'paperset': 'paperSet',
      '套次': 'paperSet',
      'score': 'score',
      '分值': 'score',
      'groupstem': 'groupStem',
      '共用题干': 'groupStem',
    };
    return aliases[normalized] ?? normalized;
  }
}
