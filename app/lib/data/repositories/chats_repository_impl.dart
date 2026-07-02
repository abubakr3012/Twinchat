import 'dart:convert';

import '../../core/database/database_helper.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chats_repository.dart';
import '../datasources/chats_remote.dart';
import '../mappers/chats_mapper.dart';

class ChatsRepositoryImpl implements ChatsRepository {
  ChatsRepositoryImpl(this._remote, {DatabaseHelper? database})
      : _db = database ?? DatabaseHelper.instance;
  final ChatsRemote _remote;
  final DatabaseHelper _db;

  @override
  Future<List<Chat>> list() async {
    // Offline-first: return cache immediately
    final cached = await _db.getCachedChats();
    final cachedChats = cached.map((row) => _chatFromDb(row)).toList();

    // Then fetch from API and update cache
    try {
      final dtos = await _remote.list();
      final fresh = dtos.map((d) => d.toDomain()).toList();

      // Update cache
      await _db.cacheChats(fresh.map((c) => _chatToDb(c)).toList());

      return fresh;
    } catch (_) {
      // If API fails, return cached data
      return cachedChats;
    }
  }

  @override
  Future<Chat> getById(int id) async {
    final dto = await _remote.getById(id);
    return dto.toDomain();
  }

  @override
  Future<Chat> create({required ChatType type, String? name}) async {
    final dto = await _remote.create(type: _typeToString(type), name: name);
    final chat = dto.toDomain();

    // Cache the created chat
    await _db.cacheChats([_chatToDb(chat)]);

    return chat;
  }

  @override
  Future<Chat> addMember({required int chatId, required int userId}) async {
    final dto = await _remote.addMember(chatId: chatId, userId: userId);
    return dto.toDomain();
  }

  @override
  Future<Chat> updateGroup({
    required int chatId,
    String? name,
    String? avatarUrl,
  }) async {
    final dto = await _remote.updateGroup(
      chatId: chatId,
      name: name,
      avatarUrl: avatarUrl,
    );
    return dto.toDomain();
  }

  String _typeToString(ChatType t) =>
      t == ChatType.group ? 'group' : 'private';

  // ─── DB helpers ──────────────────────────────────────────────────────

  Map<String, dynamic> _chatToDb(Chat c) => {
        'id': c.id,
        'type': _typeToString(c.type),
        'name': c.name,
        'avatar_url': c.avatarUrl,
        'members': jsonEncode(c.members
            .map((m) => {
                  'id': m.id,
                  'user': m.userId,
                  'username': m.username,
                  'avatar_url': m.avatarUrl,
                  'is_admin': m.isAdmin,
                })
            .toList()),
        'created_at': c.createdAt?.toIso8601String(),
      };

  Chat _chatFromDb(Map<String, dynamic> row) {
    final membersRaw = row['members'] as String? ?? '[]';
    final membersList = (jsonDecode(membersRaw) as List)
        .map((m) => ChatMember(
              id: (m['id'] as num?)?.toInt() ?? 0,
              userId: (m['user'] as num?)?.toInt() ?? 0,
              username: m['username'] as String? ?? '',
              avatarUrl: m['avatar_url'] as String?,
              isAdmin: m['is_admin'] as bool? ?? false,
            ))
        .toList();

    return Chat(
      id: (row['id'] as num).toInt(),
      type: chatTypeFromString(row['type'] as String?),
      name: row['name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      members: membersList,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String)
          : null,
    );
  }
}
