import '../../domain/entities/user.dart';
import '../models/auth_dto.dart';

extension UserDtoX on UserDto {
  User toDomain() => User(
        id: id,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        avatarUrl: avatar,
        bio: bio,
        lastSeen: lastSeen,
        isOnline: isOnline,
      );
}
