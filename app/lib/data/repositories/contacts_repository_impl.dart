import '../../domain/entities/contact.dart';
import '../../domain/repositories/contacts_repository.dart';
import '../datasources/contacts_remote.dart';
import '../mappers/contacts_mapper.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl(this._remote);
  final ContactsRemote _remote;

  @override
  Future<List<Contact>> list() async {
    final dtos = await _remote.list();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<List<Contact>> blocked() async {
    final dtos = await _remote.blocked();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<Contact> add({required int contactId, String? nickname}) async {
    final dto = await _remote.add(contactId: contactId, nickname: nickname);
    return dto.toDomain();
  }

  @override
  Future<Contact> update({required int id, String? nickname}) async {
    final dto = await _remote.update(id: id, nickname: nickname);
    return dto.toDomain();
  }

  @override
  Future<void> delete(int id) => _remote.delete(id);

  @override
  Future<void> block(int id) => _remote.block(id);

  @override
  Future<void> unblock(int id) => _remote.unblock(id);
}