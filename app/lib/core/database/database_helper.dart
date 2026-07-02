import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// SQLite database helper for local caching.
/// Provides offline-first data access.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'twinchat.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS messages');
        await db.execute('DROP TABLE IF EXISTS chats');
        await db.execute('DROP TABLE IF EXISTS settings');
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY,
        chat_id INTEGER NOT NULL,
        sender_id INTEGER NOT NULL,
        sender_username TEXT NOT NULL DEFAULT '',
        sender_avatar TEXT,
        content TEXT NOT NULL DEFAULT '',
        message_type TEXT NOT NULL DEFAULT 'text',
        created_at TEXT NOT NULL,
        is_edited INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        read_by TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_chat_id ON messages(chat_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_messages_created_at ON messages(created_at)
    ''');

    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY,
        type TEXT NOT NULL DEFAULT 'private',
        name TEXT,
        avatar_url TEXT,
        members TEXT NOT NULL DEFAULT '[]',
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ─── Messages ────────────────────────────────────────────────────────

  Future<void> cacheMessages(List<Map<String, dynamic>> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'messages',
        msg,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(int chatId) async {
    final db = await database;
    return db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessage(int id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.update(
      'messages',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMessage(int id) async {
    final db = await database;
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Chats ───────────────────────────────────────────────────────────

  Future<void> cacheChats(List<Map<String, dynamic>> chats) async {
    final db = await database;
    final batch = db.batch();
    for (final chat in chats) {
      batch.insert(
        'chats',
        chat,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedChats() async {
    final db = await database;
    return db.query('chats', orderBy: 'id DESC');
  }

  // ─── Settings ────────────────────────────────────────────────────────

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('settings');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
