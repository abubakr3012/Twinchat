import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote.dart';
import '../mappers/auth_mapper.dart';
import '../../core/storage/token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokenStorage,
  })  : _remote = remote,
        _storage = tokenStorage;

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<PhoneCodeRequestResult> requestPhoneCode(String phoneNumber) async {
    final dto = await _remote.requestPhoneCode(phoneNumber);
    return PhoneCodeRequestResult(
      phoneNumber: dto.phoneNumber,
      sent: dto.sent,
      debugCode: dto.debugCode,
    );
  }

  @override
  Future<AuthSession> verifyPhoneCode({
    required String phoneNumber,
    required String code,
  }) async {
    final dto = await _remote.verifyPhoneCode(
      phoneNumber: phoneNumber,
      code: code,
    );
    await _storage.saveTokens(access: dto.access, refresh: dto.refresh);
    return AuthSession(
      access: dto.access,
      refresh: dto.refresh,
      user: dto.user?.toDomain(),
      isNewUser: dto.isNewUser,
    );
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final dto = await _remote.login(username: username, password: password);
    await _storage.saveTokens(access: dto.access, refresh: dto.refresh);
    return AuthSession(
      access: dto.access,
      refresh: dto.refresh,
      user: dto.user?.toDomain(),
      isNewUser: false,
    );
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final dto = await _remote.register(
      username: username,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
    await _storage.saveTokens(access: dto.access, refresh: dto.refresh);
    return AuthSession(
      access: dto.access,
      refresh: dto.refresh,
      user: dto.user?.toDomain(),
      isNewUser: true,
    );
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<String?> currentAccessToken() => _storage.readAccess();

  @override
  Future<bool> isAuthenticated() => _storage.hasAccess();
}
