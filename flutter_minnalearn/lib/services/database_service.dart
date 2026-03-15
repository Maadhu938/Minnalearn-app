import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/lesson.dart';
import 'data_seeder.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'minnalearn.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> initialize() async {
    final db = await database;
    await _ensureUserStatsDefaults(db);
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM lessons');
    final lessonCount = Sqflite.firstIntValue(result) ?? 0;

    if (lessonCount == 0) {
      await _replaceLessonContent(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lessons (
        id INTEGER PRIMARY KEY,
        title TEXT,
        completed INTEGER DEFAULT 0,
        progress REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE vocabulary (
        id TEXT PRIMARY KEY,
        japanese TEXT,
        romaji TEXT,
        meaning TEXT,
        type TEXT,
        lesson_id INTEGER,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE kanji (
        id TEXT PRIMARY KEY,
        character TEXT,
        meaning TEXT,
        on_reading TEXT,
        kun_reading TEXT,
        lesson_id INTEGER,
        FOREIGN KEY (lesson_id) REFERENCES lessons (id)
      )
    ''');

    await _createUserStatsTable(db);
    await _createStudySessionsTable(db);
    await _createGameScoresTable(db);
    await _createBookmarksTable(db);
    
    // Seed initial lesson data from the bundled vocabulary file.
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    await _replaceLessonContent(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createUserStatsTable(db);
    }
    if (oldVersion < 3) {
      await _createStudySessionsTable(db);
      await _createGameScoresTable(db);
    }
    if (oldVersion < 6) {
      final progressByLessonId = await _captureLessonProgress(db);
      await _replaceLessonContent(
        db,
        progressByLessonId: progressByLessonId,
      );
    }
    if (oldVersion < 7) {
      await _createBookmarksTable(db);
    }
  }

  Future<Map<int, Map<String, dynamic>>> _captureLessonProgress(Database db) async {
    final rows = await db.query(
      'lessons',
      columns: ['id', 'completed', 'progress'],
    );

    return {
      for (final row in rows)
        row['id'] as int: {
          'completed': row['completed'] as int? ?? 0,
          'progress': (row['progress'] as num?)?.toDouble() ?? 0.0,
        },
    };
  }

  Future<void> _replaceLessonContent(
    Database db, {
    Map<int, Map<String, dynamic>> progressByLessonId = const {},
  }) async {
    final lessons = await DataSeeder.loadInitialLessons();

    await db.transaction((txn) async {
      await txn.delete('vocabulary');
      await txn.delete('kanji');
      await txn.delete('lessons');
      await _storeLessons(
        txn,
        lessons,
        progressByLessonId: progressByLessonId,
      );
    });
  }

  Future<void> _storeLessons(
    DatabaseExecutor executor,
    List<Lesson> lessons, {
    Map<int, Map<String, dynamic>> progressByLessonId = const {},
  }) async {
    for (final lesson in lessons) {
      final lessonMap = lesson.toMap();
      final existingProgress = progressByLessonId[lesson.id];
      if (existingProgress != null) {
        lessonMap['completed'] = existingProgress['completed'];
        lessonMap['progress'] = existingProgress['progress'];
      }

      await executor.insert(
        'lessons',
        lessonMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (int index = 0; index < lesson.vocabulary.length; index++) {
        await executor.insert(
          'vocabulary',
          _buildVocabularyMap(lesson.vocabulary[index], lesson.id, index),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (int index = 0; index < lesson.kanji.length; index++) {
        await executor.insert(
          'kanji',
          _buildKanjiMap(lesson.kanji[index], lesson.id, index),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Map<String, dynamic> _buildVocabularyMap(
    Vocabulary vocabulary,
    int lessonId,
    int index,
  ) {
    final map = vocabulary.toMap();
    map['id'] ??= 'lesson_${lessonId}_vocab_${(index + 1).toString().padLeft(3, '0')}';
    map['lesson_id'] = lessonId;
    return map;
  }

  Map<String, dynamic> _buildKanjiMap(
    Kanji kanji,
    int lessonId,
    int index,
  ) {
    final map = kanji.toMap();
    map['id'] ??= 'lesson_${lessonId}_kanji_${(index + 1).toString().padLeft(3, '0')}';
    map['lesson_id'] = lessonId;
    return map;
  }

  Future<void> _createUserStatsTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_stats (
        key TEXT PRIMARY KEY,
        value_int INTEGER DEFAULT 0,
        value_real REAL DEFAULT 0.0,
        value_text TEXT
      )
    ''');

    // Initialize stats
    await db.insert('user_stats', {'key': 'total_study_time_seconds', 'value_int': 0});
    await db.insert('user_stats', {'key': 'current_streak', 'value_int': 0});
    await db.insert('user_stats', {'key': 'last_study_date', 'value_text': ''});
    await db.insert('user_stats', {'key': 'onboarding_seen', 'value_int': 0});
  }

  Future<void> _ensureUserStatsDefaults(Database db) async {
    final defaultEntries = <Map<String, dynamic>>[
      {'key': 'total_study_time_seconds', 'value_int': 0},
      {'key': 'current_streak', 'value_int': 0},
      {'key': 'last_study_date', 'value_text': ''},
      {'key': 'onboarding_seen', 'value_int': 0},
    ];

    for (final entry in defaultEntries) {
      await db.insert(
        'user_stats',
        entry,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _createStudySessionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT, -- YYYY-MM-DD
        duration_seconds INTEGER
      )
    ''');
  }

  Future<void> _createGameScoresTable(Database db) async {
    await db.execute('''
      CREATE TABLE game_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_name TEXT,
        score INTEGER,
        date TEXT
      )
    ''');
  }

  Future<void> _createBookmarksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarked_vocabulary (
        vocabulary_id TEXT PRIMARY KEY,
        created_at TEXT,
        FOREIGN KEY (vocabulary_id) REFERENCES vocabulary (id)
      )
    ''');
  }

  // Stats Operations
  Future<void> addStudyTime(int seconds) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE user_stats SET value_int = value_int + ? WHERE key = ?',
      [seconds, 'total_study_time_seconds'],
    );
    
    // Log session for today
    String today = DateTime.now().toIso8601String().split('T')[0];
    final existingSession = await db.query(
      'study_sessions',
      columns: ['id', 'duration_seconds'],
      where: 'date = ?',
      whereArgs: [today],
      limit: 1,
    );

    if (existingSession.isEmpty) {
      await db.insert('study_sessions', {
        'date': today,
        'duration_seconds': seconds,
      });
    } else {
      final session = existingSession.first;
      final updatedDuration = (session['duration_seconds'] as int? ?? 0) + seconds;
      await db.update(
        'study_sessions',
        {'duration_seconds': updatedDuration},
        where: 'id = ?',
        whereArgs: [session['id']],
      );
    }
    
    await updateStreak();
  }

  Future<int> getTotalStudyTime() async {
    final db = await database;
    final result = await db.query(
      'user_stats',
      where: 'key = ?',
      whereArgs: ['total_study_time_seconds'],
    );
    if (result.isNotEmpty) {
      return result.first['value_int'] as int;
    }
    return 0;
  }

  Future<void> updateStreak() async {
    final db = await database;
    String today = DateTime.now().toIso8601String().split('T')[0];
    
    final lastStudyResult = await db.query('user_stats', where: 'key = ?', whereArgs: ['last_study_date']);
    String lastDate = lastStudyResult.isNotEmpty ? (lastStudyResult.first['value_text'] as String? ?? '') : '';

    if (lastDate == today) return; // Already updated today

    int streak = 0;
    final streakResult = await db.query('user_stats', where: 'key = ?', whereArgs: ['current_streak']);
    if (streakResult.isNotEmpty) {
      streak = (streakResult.first['value_int'] as int);
    }

    DateTime todayDT = DateTime.parse(today);
    if (lastDate != '') {
      DateTime lastDateDT = DateTime.parse(lastDate);
      int diff = todayDT.difference(lastDateDT).inDays;
      
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await db.update('user_stats', {'value_int': streak}, where: 'key = ?', whereArgs: ['current_streak']);
    await db.update('user_stats', {'value_text': today}, where: 'key = ?', whereArgs: ['last_study_date']);
  }

  Future<int> getStreak() async {
    final db = await database;
    final result = await db.query('user_stats', where: 'key = ?', whereArgs: ['current_streak']);
    return result.isNotEmpty ? (result.first['value_int'] as int) : 0;
  }

  Future<bool> hasSeenOnboarding() async {
    final db = await database;
    final result = await db.query(
      'user_stats',
      columns: ['value_int'],
      where: 'key = ?',
      whereArgs: ['onboarding_seen'],
      limit: 1,
    );

    return result.isNotEmpty && ((result.first['value_int'] as int? ?? 0) == 1);
  }

  Future<void> setOnboardingSeen(bool seen) async {
    final db = await database;
    await db.update(
      'user_stats',
      {'value_int': seen ? 1 : 0},
      where: 'key = ?',
      whereArgs: ['onboarding_seen'],
    );
  }

  Future<List<Map<String, dynamic>>> getWeeklyStudyTime() async {
    final db = await database;
    // Get last 7 days
    List<String> last7Days = [];
    for (int i = 6; i >= 0; i--) {
      last7Days.add(DateTime.now().subtract(Duration(days: i)).toIso8601String().split('T')[0]);
    }

    final placeholders = List.filled(last7Days.length, '?').join(',');
    final List<Map<String, dynamic>> sessions = await db.rawQuery(
      '''
      SELECT date, SUM(duration_seconds) as duration_seconds
      FROM study_sessions
      WHERE date IN ($placeholders)
      GROUP BY date
      ''',
      last7Days,
    );

    // Map to result ensuring all days are present
    return last7Days.map((date) {
      final session = sessions.firstWhere(
        (s) => s['date'] == date,
        orElse: () => {'date': date, 'duration_seconds': 0},
      );
      final seconds = (session['duration_seconds'] as num?)?.toInt() ?? 0;
      return {
        'day': _getDayLabel(date),
        'seconds': seconds,
        'percent': seconds / 3600, // Normalized to 1 hour
      };
    }).toList();
  }

  String _getDayLabel(String date) {
    DateTime dt = DateTime.parse(date);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }

  // Game Score Operations
  Future<void> saveGameScore(String gameName, int score) async {
    final db = await database;
    await db.insert('game_scores', {
      'game_name': gameName,
      'score': score,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentGameScores(int limit) async {
    final db = await database;
    return await db.query(
      'game_scores',
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  Future<Set<String>> getBookmarkedVocabularyIds({int? lessonId}) async {
    final db = await database;
    late final List<Map<String, Object?>> rows;

    if (lessonId == null) {
      rows = await db.query('bookmarked_vocabulary', columns: ['vocabulary_id']);
    } else {
      rows = await db.rawQuery(
        '''
        SELECT b.vocabulary_id
        FROM bookmarked_vocabulary b
        INNER JOIN vocabulary v ON v.id = b.vocabulary_id
        WHERE v.lesson_id = ?
        ''',
        [lessonId],
      );
    }

    return rows
        .map((row) => row['vocabulary_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<bool> toggleVocabularyBookmark(String vocabularyId) async {
    final db = await database;
    final existing = await db.query(
      'bookmarked_vocabulary',
      columns: ['vocabulary_id'],
      where: 'vocabulary_id = ?',
      whereArgs: [vocabularyId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'bookmarked_vocabulary',
        where: 'vocabulary_id = ?',
        whereArgs: [vocabularyId],
      );
      return false;
    }

    await db.insert('bookmarked_vocabulary', {
      'vocabulary_id': vocabularyId,
      'created_at': DateTime.now().toIso8601String(),
    });
    return true;
  }

  // Mastery Calculations
  Future<Map<String, double>> getMasteryPercentages() async {
    final db = await database;
    
    // Vocabulary mastery: sum of progress / count
    final vocabProgress = await db.rawQuery('SELECT AVG(progress) as avg FROM lessons');
    final vMastery = (vocabProgress.first['avg'] as num?)?.toDouble() ?? 0.0;

    // Kanji mastery: (similar logic or based on completed lessons)
    // For now, let's use the average progress across all lessons as a proxy
    return {
      'vocabulary': vMastery,
      'kanji': vMastery, // Placeholder: ideally separate tracking per item
      'grammar': vMastery * 0.8, // Placeholder
    };
  }

  // Lesson Operations
  Future<List<Lesson>> getLessons() async {
    final db = await database;
    final List<Map<String, dynamic>> lessonMaps = await db.query(
      'lessons',
      orderBy: 'id ASC',
    );
    
    List<Lesson> lessons = [];
    for (var lessonMap in lessonMaps) {
      final vocabData = await db.query(
        'vocabulary',
        where: 'lesson_id = ?',
        whereArgs: [lessonMap['id']],
        orderBy: 'id ASC',
      );
      final kanjiData = await db.query(
        'kanji',
        where: 'lesson_id = ?',
        whereArgs: [lessonMap['id']],
        orderBy: 'id ASC',
      );

      lessons.add(Lesson.fromMap(
        lessonMap,
        vocab: vocabData.map((v) => Vocabulary.fromMap(v)).toList(),
        kanji: kanjiData.map((k) => Kanji.fromMap(k)).toList(),
      ));
    }
    return lessons;
  }

  Future<void> updateLessonProgress(int id, double progress) async {
    final db = await database;
    await db.update(
      'lessons',
      {
        'completed': progress >= 1.0 ? 1 : 0,
        'progress': progress,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Seed Helper
  Future<void> seedData(List<Lesson> lessons) async {
    final db = await database;
    await db.transaction((txn) async {
      await _storeLessons(txn, lessons);
    });
  }

  Future<int> getCompletedLessonsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM lessons WHERE completed = 1');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalVocabularyCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM vocabulary');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalKanjiCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM kanji');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getLearnedVocabularyCount() async {
    final lessons = await getLessons();
    return lessons.fold<int>(
      0,
      (total, lesson) => total + (lesson.vocabulary.length * lesson.progress).round(),
    );
  }

  Future<int> getLearnedKanjiCount() async {
    final lessons = await getLessons();
    return lessons.fold<int>(
      0,
      (total, lesson) => total + (lesson.kanji.length * lesson.progress).round(),
    );
  }
}
