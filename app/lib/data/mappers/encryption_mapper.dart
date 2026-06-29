import '../../domain/entities/encryption.dart';
import '../models/encryption_dto.dart';

extension SafeModeStatusDtoX on SafeModeStatusDto {
  SafeModeStatus toDomain() =>
      SafeModeStatus(isActive: isActive, fingerprint: fingerprint);
}

extension SafeModeKeyShareDtoX on SafeModeKeyShareDto {
  SafeModeKeyShare toDomain() => SafeModeKeyShare(
        id: id,
        userId: userId,
        username: username,
        sharedWithId: sharedWithId,
        sharedWithUsername: sharedWithUsername,
        method: method,
        sharedAt: sharedAt,
        isRevoked: isRevoked,
      );
}

extension SafeModeUIDtoX on SafeModeUIDto {
  SafeModeUIState toDomain() => SafeModeUIState(
        keyEntered: keyEntered,
        autoLockMinutes: autoLockMinutes,
      );
}