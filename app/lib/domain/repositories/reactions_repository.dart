import '../entities/reaction.dart';

abstract class ReactionsRepository {
  Future<List<Reaction>> listForMessage(int messageId);
  Future<Reaction> add({required int messageId, required String emoji});
  Future<void> delete(int reactionId);
}
