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
    // 1. WALKING & STEPS
    await db.execute('''
      CREATE TABLE step_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        steps INTEGER NOT NULL,
        distance_meters REAL,
        calories_burned REAL,
        timestamp TEXT NOT NULL 
      )
    ''');

    // 2. WORKOUTS
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_type TEXT NOT NULL, 
        duration_minutes INTEGER,
        intensity_level INTEGER,    
        notes TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // 3. SLEEP CYCLES
    await db.execute('''
      CREATE TABLE sleep_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bedtime TEXT NOT NULL,      
        wake_time TEXT NOT NULL,    
        sleep_quality INTEGER,      
        deep_sleep_minutes INTEGER, 
        timestamp TEXT NOT NULL     
      )
    ''');

    // 4. MENTAL WELLBEING
    await db.execute('''
      CREATE TABLE mental_health_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood_score INTEGER NOT NULL, 
        stress_level INTEGER,        
        journal_entry TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // 5. HABITS (New - Replaces hardcoded UI state)
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        emoji TEXT NOT NULL,
        is_done INTEGER DEFAULT 0,
        streak INTEGER DEFAULT 0
      )
    ''');

    // 6. GOALS (New - Replaces hardcoded UI state)
    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        progress REAL DEFAULT 0.0,
        category TEXT NOT NULL,
        is_accepted INTEGER DEFAULT 0
      )
    ''');

    // Seed initial data so the UI isn't blank on first launch
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

    for (var habit in initialHabits) {
      await db.insert('habits', habit);
    }
  }

  // ==========================================
  // 📝 GENERIC CRUD OPERATIONS
  // ==========================================

  /// Insert a record into any table
  Future<int> insertRecord(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all records from a table (optional limit/order)
  Future<List<Map<String, dynamic>>> getRecords(
    String table, {
    String? orderBy,
    int? limit,
  }) async {
    final db = await instance.database;
    return await db.query(table, orderBy: orderBy, limit: limit);
  }

  /// Delete a record by ID
  Future<int> deleteRecord(String table, int id) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // 🎯 SPECIFIC FEATURE OPERATIONS
  // ==========================================

  // --- HABITS ---

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

  // --- GOALS ---

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

  Future<int> updateGoalProgress(int id, double progress) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      {'progress': progress},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- VITALS & LOGS (Metrics) ---

  Future<void> logHeartRate(int bpm) async {
    // Usually, you'd store this in a dedicated heart_rate table
    // For now, we can use the mental_health_logs or create a new table
    // if you want to track high-frequency HR data locally.
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
      'journal_entry': notes ?? '', // ⚡ Stores the questionnaire scores
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
