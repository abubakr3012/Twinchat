/// Высокоуровневые операции E2E-шифрования сообщений.
///
/// Поток:
/// 1. Каждый пользователь при регистрации генерирует пару X25519 ключей.
/// 2. Свой private key хранит в [KeyManager] (только на устройстве).
/// 3. Свой public key отдаёт серверу (таблица `user_key.public_key`).
/// 4. Public keys других пользователей получает с сервера и кеширует.
/// 5. При отправке сообщения:
///    - ECDH(my_priv, recipient_pub) → shared secret (32 байта)
///    - HKDF-SHA256(shared, info=conversationId) → 32-байтовый AES key
///    - AES-256-GCM(plaintext, aes_key, random_iv)
///    - на сервер: encrypted_text (base64)
/// 6. При получении — обратный поток.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

import 'aes_gcm.dart';
import 'x25519_keys.dart';

class MessageCrypto {
  MessageCrypto._();

  /// Вывести 32-байтовый AES-ключ из общего секрета через HKDF-SHA256.
  static Future<Uint8List> deriveSessionKey({
    required Uint8List sharedSecret,
    required String conversationId,
  }) async {
    final hkdf = crypto.Hkdf(
      hmac: crypto.Hmac.sha256(),
      outputLength: 32,
    );
    final result = await hkdf.deriveKey(
      secretKey: crypto.SecretKey(sharedSecret),
      nonce: Uint8List.fromList(utf8.encode(conversationId)),
    );
    final bytes = await result.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Зашифровать сообщение для получателя.
  static Future<String> encryptForRecipient({
    required Uint8List myPrivateKey,
    required Uint8List recipientPublicKey,
    required String conversationId,
    required String plaintext,
  }) async {
    final shared = await _sharedSecret(
      myPrivateKey: myPrivateKey,
      peerPublicKey: recipientPublicKey,
    );
    final key = await deriveSessionKey(
      sharedSecret: shared,
      conversationId: conversationId,
    );
    return AesGcm.encryptStringToBase64(plaintext: plaintext, key: key);
  }

  /// Расшифровать сообщение от отправителя.
  static Future<String> decryptFromSender({
    required Uint8List myPrivateKey,
    required Uint8List senderPublicKey,
    required String conversationId,
    required String encryptedTextB64,
  }) async {
    final shared = await _sharedSecret(
      myPrivateKey: myPrivateKey,
      peerPublicKey: senderPublicKey,
    );
    final key = await deriveSessionKey(
      sharedSecret: shared,
      conversationId: conversationId,
    );
    return AesGcm.decryptBase64ToString(input: encryptedTextB64, key: key);
  }

  /// Зашифровать файл (байты) для получателя.
  static Future<AesGcmCipher> encryptFileForRecipient({
    required Uint8List myPrivateKey,
    required Uint8List recipientPublicKey,
    required String conversationId,
    required Uint8List fileBytes,
  }) async {
    final shared = await _sharedSecret(
      myPrivateKey: myPrivateKey,
      peerPublicKey: recipientPublicKey,
    );
    final key = await deriveSessionKey(
      sharedSecret: shared,
      conversationId: conversationId,
    );
    return AesGcm.encryptBytes(plaintext: fileBytes, key: key);
  }

  /// Расшифровать файл от отправителя.
  static Future<Uint8List> decryptFileFromSender({
    required Uint8List myPrivateKey,
    required Uint8List senderPublicKey,
    required String conversationId,
    required AesGcmCipher cipher,
  }) async {
    final shared = await _sharedSecret(
      myPrivateKey: myPrivateKey,
      peerPublicKey: senderPublicKey,
    );
    final key = await deriveSessionKey(
      sharedSecret: shared,
      conversationId: conversationId,
    );
    return AesGcm.decryptToBytes(cipher: cipher, key: key);
  }

  /// Fingerprint ключа чата (8 base58 символов).
  static Future<String> fingerprint(Uint8List sessionKey) async {
    final digest = await crypto.Sha256().hash(sessionKey);
    final bytes = Uint8List.fromList(digest.bytes);
    return _base58(Uint8List.sublistView(bytes, 0, 8)).substring(0, 8);
  }

  static Future<Uint8List> _sharedSecret({
    required Uint8List myPrivateKey,
    required Uint8List peerPublicKey,
  }) async {
    final mine = await X25519KeyPair.fromPrivateSeed(myPrivateKey);
    final remote = await X25519KeyPair.fromPublicKeyBase64(base64.encode(peerPublicKey));
    return mine.sharedSecretWith(remote);
  }

  static const _alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  static String _base58(Uint8List bytes) {
    var n = BigInt.zero;
    for (final b in bytes) {
      n = n * BigInt.from(256) + BigInt.from(b);
    }
    var result = '';
    while (n > BigInt.zero) {
      final r = n % BigInt.from(58);
      n = n ~/ BigInt.from(58);
      result = '${_alphabet[r.toInt()]}$result';
    }
    for (final b in bytes) {
      if (b == 0) {
        result = '1$result';
      } else {
        break;
      }
    }
    return result;
  }
}