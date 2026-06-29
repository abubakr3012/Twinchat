import '../entities/chat.dart';

abstract class ChatsRepository {
  Future<List<Chat>> list();
  Future<Chat> getById(int id);
  Future<Chat> create({required ChatType type, String? name});
}
