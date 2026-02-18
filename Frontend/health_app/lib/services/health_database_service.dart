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
      // Generate a cryptographically secure 32-byte key
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
      password: password, // This enables SQLCipher encryption
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 1. WALKING & STEPS (High-frequency data)
    await db.execute('''
    CREATE TABLE step_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      steps INTEGER NOT NULL,
      distance_meters REAL,
      calories_burned REAL,
      timestamp TEXT NOT NULL -- Store as ISO8601
    )
  ''');

    // 2. WORKOUTS (Session-based data)
    await db.execute('''
    CREATE TABLE workouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      workout_type TEXT NOT NULL, -- e.g., 'Running', 'Weightlifting', 'Yoga'
      duration_minutes INTEGER,
      intensity_level INTEGER,    -- 1 to 10 scale
      notes TEXT,
      timestamp TEXT NOT NULL
    )
  ''');

    // 3. SLEEP CYCLES (Time-range data)
    // Normalization tip: Use startTime and endTime to calculate duration
    await db.execute('''
    CREATE TABLE sleep_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bedtime TEXT NOT NULL,      -- When they went to bed
      wake_time TEXT NOT NULL,    -- When they woke up
      sleep_quality INTEGER,      -- 1 to 5 scale
      deep_sleep_minutes INTEGER, -- If you integrate a wearable API later
      timestamp TEXT NOT NULL     -- Recording date
    )
  ''');

    // 4. MENTAL WELLBEING (Qualitative data)
    await db.execute('''
    CREATE TABLE mental_health_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      mood_score INTEGER NOT NULL, -- 1 to 10
      stress_level INTEGER,        -- 1 to 10
      journal_entry TEXT,
      timestamp TEXT NOT NULL
    )
  ''');
  }
}
