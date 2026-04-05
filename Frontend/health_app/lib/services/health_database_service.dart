import 'dart:convert';
import 'dart:math';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HealthDatabaseService {
  static final HealthDatabaseService instance = HealthDatabaseService._init();
  static Database? _database;
  final _storage = const FlutterSecureStorage();

  HealthDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('user_health_data.db');
    return _database!;
  }

  Future<String> _getOrGenerateEncryptionKey() async {
    const keyName = 'health_db_key';
    String? existingKey = await _storage.read(key: keyName);

    if (existingKey == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      String newKey = base64Url.encode(values);
      await _storage.write(key: keyName, value: newKey);
      return newKey;
    }
    return existingKey;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    final password = await _getOrGenerateEncryptionKey();

    return await openDatabase(
      path,
      version: 1,
      password: password,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // We use a batch to execute table and index creation efficiently
    final batch = db.batch();

    // 1. WALKING & STEPS
    batch.execute('''
      CREATE TABLE step_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        steps INTEGER NOT NULL,
        distance_meters REAL,
        calories_burned REAL,
        timestamp TEXT NOT NULL 
      )
    ''');
    batch.execute('CREATE INDEX idx_steps_time ON step_logs(timestamp)');

    // 2. WORKOUTS
    batch.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_type TEXT NOT NULL, 
        duration_minutes INTEGER,
        intensity_level INTEGER,    
        notes TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
    batch.execute('CREATE INDEX idx_workouts_time ON workouts(timestamp)');

    // 3. SLEEP CYCLES
    batch.execute('''
      CREATE TABLE sleep_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bedtime TEXT NOT NULL,      
        wake_time TEXT NOT NULL,    
        sleep_quality INTEGER,      
        deep_sleep_minutes INTEGER, 
        timestamp TEXT NOT NULL   
      )
    ''');
    batch.execute('CREATE INDEX idx_sleep_time ON sleep_logs(timestamp)');

    // 4. MENTAL WELLBEING
    batch.execute('''
      CREATE TABLE mental_health_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_score INTEGER NOT NULL, 
        stress_level INTEGER,        
        journal_entry TEXT,
        timestamp TEXT NOT NULL
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_mental_time ON mental_health_logs(timestamp)',
    );

    // 5. HABITS
    batch.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        emoji TEXT NOT NULL,
        is_done INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0
      )
    ''');

    // 6. GOALS
    batch.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        category TEXT NOT NULL,
        is_accepted INTEGER DEFAULT 0
      )
    ''');

    await batch.commit(noResult: true);
    await _seedInitialHabits(db);
  }

  // ==========================================
  // 🛠️ SEED DATA
  // ==========================================

  Future<void> _seedInitialHabits(Database db) async {
    final initialHabits = [
      {
        'title': 'Drink 8 glasses of water',
        'emoji': '💧',
        'is_done': 0,
        'streak': 0,
      },
      {
        'title': 'Complete breathing exercise',
        'emoji': '🧘',
        'is_done': 0,
        'streak': 0,
      },
      {'title': 'Walk 5,000 steps', 'emoji': '🚶', 'is_done': 0, 'streak': 0},
      {'title': 'Sleep 7+ hours', 'emoji': '😴', 'is_done': 0, 'streak': 0},
      {'title': 'Meditate 5 minutes', 'emoji': '🧠', 'is_done': 0, 'streak': 0},
    ];

    final batch = db.batch();
    for (var habit in initialHabits) {
      batch.insert('habits', habit);
    }
    await batch.commit(noResult: true);
  }

  // ==========================================
  // 📝 GENERIC CRUD OPERATIONS & BATCHING
  // ==========================================

  Future<int> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// ⚡ OPTIMIZATION: Batch insert for watch syncing
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var record in records) {
      batch.insert(table, record, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getRecords(
    String table, {
    String? orderBy,
    int? limit,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await instance.database;
    return await db.query(
      table,
      orderBy: orderBy,
      limit: limit,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // 🎯 SPECIFIC FEATURE OPERATIONS
  // ==========================================

  Future<List<Map<String, dynamic>>> getHabits() async {
    return await getRecords('habits', orderBy: 'id ASC');
  }

  Future<int> toggleHabitStatus(int id, bool isDone) async {
    final db = await instance.database;
    return await db.update(
      'habits',
      {'is_done': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    return await getRecords('goals', orderBy: 'id ASC');
  }

  Future<int> acceptGoal(int id) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      {'is_accepted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> logSteps(int steps, double distance, double calories) async {
    await insertRecord('step_logs', {
      'steps': steps,
      'distance_meters': distance,
      'calories_burned': calories,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logMood(int score, int stressLevel, [String? notes]) async {
    await insertRecord('mental_health_logs', {
      'mood_score': score,
      'stress_level': stressLevel,
      'journal_entry': notes ?? '',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
