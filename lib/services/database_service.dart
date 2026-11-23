import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/question.dart';

/// 本地数据库服务：管理导入题库与答题记录。
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'yingxiang_tiku.db';
  static const int _dbVersion = 1;

  Database? _db;

  /// 测试专用：覆盖数据库工厂与数据库路径。
  static DatabaseFactory? _factoryOverride;
  static String? _pathOverride;

  /// 测试时注入自定义数据库工厂与路径（如 sqflite_common_ffi 内存库）。
  static void overrideForTest({DatabaseFactory? factory, String? path}) {
    _factoryOverride = factory;
    _pathOverride = path;
    instance._db = null;
  }

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final DatabaseFactory factory = _factoryOverride ?? databaseFactory;
    final String path = _pathOverride ??
        p.join(await factory.getDatabasesPath(), _dbName);
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onConfigure: (Database db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paper_set INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        chapter TEXT NOT NULL DEFAULT '',
        stem TEXT NOT NULL,
        group_stem TEXT,
        options TEXT NOT NULL DEFAULT '[]',
        answer TEXT NOT NULL DEFAULT '',
        analysis TEXT NOT NULL DEFAULT '',
        score REAL NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'imported'
      )
    ''');
    await db.execute('''
      CREATE TABLE answer_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_stem TEXT,
        user_answer TEXT,
        is_correct INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  /// 查询全部导入题目。
  Future<List<Question>> getImportedQuestions() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'questions',
      where: 'source = ?',
      whereArgs: <Object>[QuestionSource.imported],
      orderBy: 'id DESC',
    );
    return rows.map(Question.fromMap).toList();
  }

  /// 批量插入导入题目（跳过 id，由数据库自增），返回实际插入数量。
  Future<int> insertImportedQuestions(List<Question> questions) async {
    if (questions.isEmpty) return 0;
    final Database db = await database;
    final Batch batch = db.batch();
    for (final Question q in questions) {
      final Map<String, dynamic> map = q.toMap()..remove('id');
      map['source'] = QuestionSource.imported;
      batch.insert('questions', map);
    }
    final List<Object?> results = await batch.commit(noResult: false);
    return results.length;
  }

  /// 删除单条导入题目。
  Future<void> deleteImportedQuestion(int id) async {
    final Database db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: <Object>[id]);
  }

  /// 清空全部导入题目。
  Future<void> clearImportedQuestions() async {
    final Database db = await database;
    await db.delete('questions', where: 'source = ?', whereArgs: <Object>[
      QuestionSource.imported,
    ]);
  }

  /// 插入一条答题记录。
  Future<void> insertAnswerRecord({
    required String stem,
    required String userAnswer,
    required bool correct,
  }) async {
    final Database db = await database;
    await db.insert('answer_records', <String, dynamic>{
      'question_stem': stem,
      'user_answer': userAnswer,
      'is_correct': correct ? 1 : 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 查询最近的答题记录（最多 [limit] 条）。
  Future<List<Map<String, dynamic>>> getAnswerRecords({int limit = 100}) async {
    final Database db = await database;
    return db.query(
      'answer_records',
      orderBy: 'id DESC',
      limit: limit,
    );
  }

  /// 关闭数据库（可选）。
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
