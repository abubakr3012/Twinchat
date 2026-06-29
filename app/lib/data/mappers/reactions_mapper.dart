import '../../domain/entities/reaction.dart';
import '../models/reactions_dto.dart';

extension ReactionDtoX on ReactionDto {
  Reaction toDomain() => Reaction(
        id: id,
        messageId: messageId,
        userId: userId,
        username: username,
        emoji: emoji,
      );
}