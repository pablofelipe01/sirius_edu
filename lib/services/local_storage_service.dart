import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/student_profile.dart';
import '../models/lesson.dart';
import '../models/assignment.dart';
import '../models/submission.dart';

/// Servicio de almacenamiento local SQLite para la app Flutter.
/// Guarda datos offline: perfil, lecciones, tareas, entregas, chat con IA.
class LocalStorageService {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'sirius_edu.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_profile (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lessons (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assignments (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS submissions (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        question TEXT NOT NULL,
        response TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // --- Profile ---

  Future<void> saveProfile(StudentProfile profile) async {
    final db = await database;
    await db.insert(
      'student_profile',
      {'id': profile.id, 'data': jsonEncode(profile.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<StudentProfile?> getProfile(String id) async {
    final db = await database;
    final results = await db.query('student_profile', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return StudentProfile.fromJson(jsonDecode(results.first['data'] as String));
  }

  // --- Lessons ---

  Future<void> saveLesson(Lesson lesson) async {
    final db = await database;
    await db.insert(
      'lessons',
      {
        'id': lesson.id,
        'data': jsonEncode(lesson.toJson()),
        'is_active': lesson.isActive ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Lesson?> getActiveLesson() async {
    final db = await database;
    final results = await db.query(
      'lessons',
      where: 'is_active = 1',
      orderBy: 'rowid DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Lesson.fromJson(jsonDecode(results.first['data'] as String));
  }

  Future<List<Lesson>> getAllLessons() async {
    final db = await database;
    final results = await db.query('lessons', orderBy: 'rowid DESC');
    return results
        .map((r) => Lesson.fromJson(jsonDecode(r['data'] as String)))
        .toList();
  }

  // --- Assignments ---

  Future<void> saveAssignment(Assignment assignment) async {
    final db = await database;
    await db.insert(
      'assignments',
      {'id': assignment.id, 'data': jsonEncode(assignment.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Assignment>> getAssignments({String? studentId}) async {
    final db = await database;
    final results = await db.query('assignments', orderBy: 'rowid DESC');
    final assignments = results
        .map((r) => Assignment.fromJson(jsonDecode(r['data'] as String)))
        .toList();
    if (studentId != null) {
      return assignments
          .where((a) => a.studentId == null || a.studentId == studentId)
          .toList();
    }
    return assignments;
  }

  Future<Assignment?> getAssignment(String id) async {
    final db = await database;
    final results = await db.query('assignments', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return Assignment.fromJson(jsonDecode(results.first['data'] as String));
  }

  // --- Submissions ---

  Future<void> saveSubmission(Submission submission) async {
    final db = await database;
    await db.insert(
      'submissions',
      {'id': submission.id, 'data': jsonEncode(submission.toJson())},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Submission>> getSubmissions({String? studentId}) async {
    final db = await database;
    final results = await db.query('submissions', orderBy: 'rowid DESC');
    final submissions = results
        .map((r) => Submission.fromJson(jsonDecode(r['data'] as String)))
        .toList();
    if (studentId != null) {
      return submissions.where((s) => s.studentId == studentId).toList();
    }
    return submissions;
  }

  // --- AI Conversations ---

  Future<void> saveConversation(String studentId, String question, String response) async {
    final db = await database;
    await db.insert('ai_conversations', {
      'student_id': studentId,
      'question': question,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, String>>> getConversations(String studentId, {int limit = 20}) async {
    final db = await database;
    final results = await db.query(
      'ai_conversations',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'id DESC',
      limit: limit,
    );
    return results.map((r) => {
      'question': r['question'] as String,
      'response': r['response'] as String,
      'timestamp': r['timestamp'] as String,
    }).toList();
  }

  // --- Config ---

  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getConfig(String key) async {
    final db = await database;
    final results = await db.query('app_config', where: 'key = ?', whereArgs: [key]);
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
