import '../../domain/entities/reaction.dart';
import '../../domain/repositories/reactions_repository.dart';
import '../datasources/reactions_remote.dart';
import '../mappers/reactions_mapper.dart';

class ReactionsRepositoryImpl implements ReactionsRepository {
  ReactionsRepositoryImpl(this._remote);
  final ReactionsRemote _remote;

  @override
  Future<List<Reaction>> listForMessage(int messageId) async {
    final dtos = await _remote.listForMessage(messageId);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Reaction> add({required int messageId, required String emoji}) async {
    final dto = await _remote.add(messageId: messageId, emoji: emoji);
    return dto.toDomain();
  }

  @override
  Future<void> delete(int reactionId) => _remote.delete(reactionId);
}