import '../../domain/entities/contact.dart';
import '../models/contacts_dto.dart';

extension ContactDtoX on ContactDto {
  Contact toDomain() => Contact(
        id: id,
        contactId: contactId,
        username: contactUsername,
        nickname: nickname,
        isBlocked: isBlocked,
        addedAt: addedAt,
      );
}