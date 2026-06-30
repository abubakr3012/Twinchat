/// Локальное хранилище своей пары X25519 ключей.
///
/// Private key хранится ТОЛЬКО на устройстве в [flutter_secure_storage].
/// Public key отдаётся серверу при регистрации / смене устройства.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'x25519_keys.dart';

class KeyManager {
  KeyManager(this._storage);

  static const _privateKeyKey = 'x25519_private_seed';
  static const _publicKeyKey = 'x25519_public_key';

  final FlutterSecureStorage _storage;

  /// Получить или сгенерировать новую пару ключей.
  Future<X25519KeyPair> getOrCreate() async {
    final seedB64 = await _storage.read(key: _privateKeyKey);
    final pubB64 = await _storage.read(key: _publicKeyKey);

    if (seedB64 != null &&
        pubB64 != null &&
        seedB64.isNotEmpty &&
        pubB64.isNotEmpty) {
      // Восстанавливаем из сохранённого seed.
      final pair = await X25519KeyPair.fromPrivateSeedBase64(seedB64);
      return pair;
    }

    final pair = await X25519KeyGenerator.generate();
    await _storage.write(
      key: _privateKeyKey,
      value: pair.privateKeyToBase64(),
    );
    await _storage.write(
      key: _publicKeyKey,
      value: pair.publicKeyToBase64(),
    );
    return pair;
  }

  /// Public key в base64 — для отправки на сервер.
  Future<String> getPublicKeyBase64() async {
    final pair = await getOrCreate();
    return pair.publicKeyToBase64();
  }

  /// Удалить все ключи (при logout).
  Future<void> clear() async {
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _publicKeyKey);
  }

  /// Извлечь Uint8List private seed (для MessageCrypto).
  Future<Uint8List> getPrivateKeyBytes() async {
    final b64 = await _storage.read(key: _privateKeyKey);
    if (b64 == null) {
      throw StateError('Private key not initialized');
    }
    return Uint8List.fromList(base64.decode(b64));
  }
}