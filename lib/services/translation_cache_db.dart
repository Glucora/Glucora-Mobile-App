import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TranslationCacheDb {
  static Database? _db;

  /// Opens (or creates) the database once, returns the same instance after that
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'translations.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE translations (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            lang      TEXT    NOT NULL,
            source    TEXT    NOT NULL,
            result    TEXT    NOT NULL,
            cached_at INTEGER NOT NULL,
            UNIQUE(lang, source)        -- prevents duplicate rows
          )
        ''');

        // Index makes lookups by lang+source very fast
        await db.execute('''
          CREATE INDEX idx_lang_source ON translations(lang, source)
        ''');
      },
    );
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  /// Returns the cached translation, or null if not found / expired
  Future<String?> get(String lang, String source, {int? maxAgeSeconds}) async {
    final db = await database;

    final rows = await db.query(
      'translations',
      columns: ['result', 'cached_at'],
      where: 'lang = ? AND source = ?',
      whereArgs: [lang, source],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    // Optional expiry check — skip if maxAgeSeconds not provided
    if (maxAgeSeconds != null) {
      final cachedAt = rows.first['cached_at'] as int;
      final age = DateTime.now().millisecondsSinceEpoch ~/ 1000 - cachedAt;
      if (age > maxAgeSeconds) {
        await delete(lang, source); // stale — remove it
        return null;
      }
    }

    return rows.first['result'] as String;
  }

  /// Fetches multiple source strings at once for a given lang.
  /// Returns a map of { source: result } for whatever was found.
  Future<Map<String, String>> getMany(
    String lang,
    List<String> sources,
  ) async {
    if (sources.isEmpty) return {};
    final db = await database;

    // SQLite IN clause with placeholders
    final placeholders = List.filled(sources.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT source, result FROM translations WHERE lang = ? AND source IN ($placeholders)',
      [lang, ...sources],
    );

    return {for (final row in rows) row['source'] as String: row['result'] as String};
  }

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Inserts or updates a single translation
  Future<void> put(String lang, String source, String result) async {
    final db = await database;
    await db.insert(
      'translations',
      {
        'lang': lang,
        'source': source,
        'result': result,
        'cached_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts many translations in a single transaction (fast for batches)
  Future<void> putMany(
    String lang,
    Map<String, String> translations,
  ) async {
    if (translations.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      for (final entry in translations.entries) {
        batch.insert(
          'translations',
          {
            'lang': lang,
            'source': entry.key,
            'result': entry.value,
            'cached_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true); // noResult = faster, skip row IDs
    });
  }

  // ─── Housekeeping ────────────────────────────────────────────────────────

  Future<void> delete(String lang, String source) async {
    final db = await database;
    await db.delete(
      'translations',
      where: 'lang = ? AND source = ?',
      whereArgs: [lang, source],
    );
  }

  /// Wipes all cached translations for a specific language
  Future<void> clearLanguage(String lang) async {
    final db = await database;
    await db.delete('translations', where: 'lang = ?', whereArgs: [lang]);
  }

  /// Deletes entries older than [days] days across all languages
  Future<void> pruneOlderThan(int days) async {
    final db = await database;
    final cutoff = DateTime.now()
            .subtract(Duration(days: days))
            .millisecondsSinceEpoch ~/
        1000;
    await db.delete(
      'translations',
      where: 'cached_at < ?',
      whereArgs: [cutoff],
    );
  }
}