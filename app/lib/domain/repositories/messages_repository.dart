import '../entities/message.dart';

abstract class MessagesRepository {
  Future<List<Message>> listForChat(int chatId);
  Future<Message> send({
    required int chatId,
    required String content,
    required MessageType messageType,
  });
  Future<Message> edit({required int messageId, required String content});
  Future<void> delete(int messageId);
}
