import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Хранилище JWT-токенов через flutter_secure_storage.
class TokenStorage {
  TokenStorage(this._storage);

  static const _accessKey = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';

  final FlutterSecureStorage _storage;

  Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<bool> hasAccess() async {
    final v = await _storage.read(key: _accessKey);
    return v != null && v.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
