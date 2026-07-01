import 'dart:convert';

import '../../core/database/database_helper.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote.dart';
import '../mappers/messages_mapper.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote, {DatabaseHelper? database})
      : _db = database ?? DatabaseHelper.instance;
  final MessagesRemote _remote;
  final DatabaseHelper _db;

  @override
  Future<List<Message>> listForChat(int chatId) async {
    // Offline-first: return cache immediately
    final cached = await _db.getCachedMessages(chatId);
    final cachedMessages = cached.map((row) => _messageFromDb(row)).toList();

    // Then fetch from API and update cache
    try {
      final dtos = await _remote.listForChat(chatId);
      final fresh = dtos.map((d) => d.toDomain()).toList();

      // Update cache
      await _db.cacheMessages(fresh.map((m) => _messageToDb(m)).toList());

      return fresh;
    } catch (_) {
      // If API fails, return cached data
      return cachedMessages;
    }
  }

  @override
  Future<Message> send({
    required int chatId,
    required String content,
    required MessageType messageType,
  }) async {
    final dto = await _remote.send(
      chatId: chatId,
      content: content,
      messageType: _typeToString(messageType),
    );
    final msg = dto.toDomain();

    // Cache the sent message
    await _db.insertMessage(_messageToDb(msg));

    return msg;
  }

  @override
  Future<Message> edit({required int messageId, required String content}) async {
    final dto = await _remote.edit(id: messageId, content: content);
    final msg = dto.toDomain();

    // Update cache
    await _db.updateMessage(messageId, {
      'content': content,
      'is_edited': 1,
    });

    return msg;
  }

  @override
  Future<void> delete(int messageId) async {
    await _remote.delete(messageId);
    await _db.updateMessage(messageId, {
      'is_deleted': 1,
      'content': 'Удалено',
    });
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  String _typeToString(MessageType t) {
    switch (t) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.audio:
        return 'audio';
      case MessageType.video:
        return 'video';
      case MessageType.file:
        return 'file';
      case MessageType.system:
      case MessageType.unknown:
        return 'text';
    }
  }

  Map<String, dynamic> _messageToDb(Message m) => {
        'id': m.id,
        'chat_id': m.chatId,
        'sender_id': m.senderId,
        'sender_username': m.senderUsername,
        'content': m.content,
        'message_type': _typeToString(m.messageType),
        'created_at': m.createdAt.toIso8601String(),
        'is_edited': m.isEdited ? 1 : 0,
        'is_deleted': m.isDeleted ? 1 : 0,
        'read_by': jsonEncode(m.readBy),
      };

  Message _messageFromDb(Map<String, dynamic> row) => Message(
        id: (row['id'] as num).toInt(),
        chatId: (row['chat_id'] as num).toInt(),
        senderId: (row['sender_id'] as num).toInt(),
        senderUsername: row['sender_username'] as String? ?? '',
        content: row['content'] as String? ?? '',
        messageType: messageTypeFromString(row['message_type'] as String?),
        createdAt: DateTime.parse(row['created_at'] as String),
        isEdited: (row['is_edited'] as int? ?? 0) == 1,
        isDeleted: (row['is_deleted'] as int? ?? 0) == 1,
        readBy: (jsonDecode(row['read_by'] as String? ?? '[]') as List)
            .map((e) => (e as num).toInt())
            .toList(),
      );
}
