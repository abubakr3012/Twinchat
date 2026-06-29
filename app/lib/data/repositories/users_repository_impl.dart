import '../../domain/entities/user.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote.dart';
import '../mappers/auth_mapper.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._remote);
  final UsersRemote _remote;

  @override
  Future<User> me() async => (await _remote.me()).toDomain();

  @override
  Future<User> getById(int id) async =>
      (await _remote.getById(id)).toDomain();

  @override
  Future<List<User>> search(String query) async {
    final dtos = await _remote.search(query);
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<User> update({
    String? username,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
  }) async {
    final dto = await _remote.update(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      bio: bio,
    );
    return dto.toDomain();
  }
}