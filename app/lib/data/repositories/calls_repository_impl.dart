import '../../domain/entities/call.dart';
import '../../domain/repositories/calls_repository.dart';
import '../datasources/calls_remote.dart';
import '../mappers/calls_mapper.dart';

class CallsRepositoryImpl implements CallsRepository {
  CallsRepositoryImpl(this._remote);
  final CallsRemote _remote;

  @override
  Future<List<Call>> list() async {
    final dtos = await _remote.list();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Call> getById(int id) async {
    final dto = await _remote.getById(id);
    return dto.toDomain();
  }

  @override
  Future<Call> create({required int chatId, required CallType type}) async {
    final dto = await _remote.create(
      chatId: chatId,
      callType: _typeToString(type),
    );
    return dto.toDomain();
  }

  @override
  Future<void> accept(int id) => _remote.accept(id);

  @override
  Future<void> reject(int id) => _remote.reject(id);

  @override
  Future<void> end(int id) => _remote.end(id);

  @override
  Future<void> leave(int id) => _remote.leave(id);

  String _typeToString(CallType t) =>
      t == CallType.video ? 'video' : 'voice';
}