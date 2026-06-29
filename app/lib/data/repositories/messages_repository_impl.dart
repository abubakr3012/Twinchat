import '../../domain/entities/message.dart';
import '../../domain/repositories/messages_repository.dart';
import '../datasources/messages_remote.dart';
import '../mappers/messages_mapper.dart';

class MessagesRepositoryImpl implements MessagesRepository {
  MessagesRepositoryImpl(this._remote);
  final MessagesRemote _remote;

  @override
  Future<List<Message>> listForChat(int chatId) async {
    final dtos = await _remote.listForChat(chatId);
    return dtos.map((d) => d.toDomain()).toList();
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
    return dto.toDomain();
  }

  @override
  Future<Message> edit({required int messageId, required String content}) async {
    final dto = await _remote.edit(id: messageId, content: content);
    return dto.toDomain();
  }

  @override
  Future<void> delete(int messageId) => _remote.delete(messageId);

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
}