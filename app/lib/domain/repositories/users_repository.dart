import '../entities/user.dart';

abstract class UsersRepository {
  Future<User> me();
  Future<User> getById(int id);
  Future<List<User>> search(String query);
  Future<User> update({
    String? username,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  });
}
