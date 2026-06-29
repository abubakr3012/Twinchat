import '../../domain/entities/chat.dart';
import '../../domain/repositories/chats_repository.dart';
import '../datasources/chats_remote.dart';
import '../mappers/chats_mapper.dart';

class ChatsRepositoryImpl implements ChatsRepository {
  ChatsRepositoryImpl(this._remote);
  final ChatsRemote _remote;

  @override
  Future<List<Chat>> list() async {
    final dtos = await _remote.list();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Chat> getById(int id) async {
    final dto = await _remote.getById(id);
    return dto.toDomain();
  }

  @override
  Future<Chat> create({required ChatType type, String? name}) async {
    final dto = await _remote.create(type: _typeToString(type), name: name);
    return dto.toDomain();
  }

  String _typeToString(ChatType t) =>
      t == ChatType.group ? 'group' : 'private';
}
