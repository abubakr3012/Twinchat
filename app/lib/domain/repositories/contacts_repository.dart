import '../entities/contact.dart';

abstract class ContactsRepository {
  Future<List<Contact>> list();
  Future<List<Contact>> blocked();
  Future<Contact> add({required int contactId, String? nickname});
  Future<Contact> update({required int id, String? nickname});
  Future<void> delete(int id);
  Future<void> block(int id);
  Future<void> unblock(int id);
}
