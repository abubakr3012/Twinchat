import '../entities/chat.dart';

abstract class ChatsRepository {
  Future<List<Chat>> list();
  Future<Chat> getById(int id);
  Future<Chat> create({required ChatType type, String? name});
  Future<Chat> addMember({required int chatId, required int userId});
  Future<Chat> updateGroup({
    required int chatId,
    String? name,
    String? avatarUrl,
  });
}
