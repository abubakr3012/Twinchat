import '../../domain/entities/call.dart';
import '../models/calls_dto.dart';

extension CallDtoX on CallDto {
  Call toDomain() => Call(
        id: id,
        chatId: chatId,
        initiatorId: initiatorId,
        initiatorUsername: initiatorUsername,
        callType: callTypeFromString(callType),
        status: callStatusFromString(status),
        startedAt: startedAt,
        endedAt: endedAt,
        durationSeconds: durationSeconds,
        createdAt: createdAt,
      );
}