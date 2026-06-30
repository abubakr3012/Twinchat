/// Safe Mode — клиентский второй слой шифрования поверх E2E.
///
/// Концепция (см. sql.sql):
/// - Отправитель при включённом safe_mode генерирует AES-256 ключ.
/// - Ключ показывается пользователю ОДИН раз (seed-фраза) и сохраняется
///   на сервере в зашифрованном виде (обёрнутый публичным ключом пользователя).
/// - Каждое сообщение в safe_mode шифруется ДВАЖДЫ:
///     plaintext → AES(safe_key) → E2E(recipient_pub)
///   На сервере `message.safe_mode_encrypted = true`.
/// - Получатель видит мусор до тех пор, пока не введёт safe-ключ отправителя.
/// - Safe-ключ живёт ТОЛЬКО в памяти UI (`MemorySafeKeyStore`), не в secure storage.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

import 'aes_gcm.dart';

/// Хранилище safe-ключей в памяти (НЕ на диске).
class MemorySafeKeyStore {
  MemorySafeKeyStore._();
  static final MemorySafeKeyStore instance = MemorySafeKeyStore._();

  final Map<String, Uint8List> _keys = <String, Uint8List>{};

  void put(String fingerprint, Uint8List key) => _keys[fingerprint] = key;
  Uint8List? get(String fingerprint) => _keys[fingerprint];
  void remove(String fingerprint) => _keys.remove(fingerprint);
  void clear() => _keys.clear();
  bool hasKey(String fingerprint) => _keys.containsKey(fingerprint);
}

/// Утилиты Safe Mode.
class SafeModeCrypto {
  SafeModeCrypto._();

  /// Сгенерировать новый safe-ключ (32 байта, AES-256).
  static Uint8List generateSafeKey() => AesGcm.generateKey();

  /// Fingerprint ключа (8 base58 символов от SHA-256).
  static Future<String> fingerprint(Uint8List safeKey) async {
    final digest = await crypto.Sha256().hash(safeKey);
    final bytes = Uint8List.fromList(digest.bytes);
    return _base58(Uint8List.sublistView(bytes, 0, 8)).substring(0, 8);
  }

  /// Зашифровать safe-ключ публичным ключом получателя (X25519 ECDH + AES-wrap).
  ///
  /// Формат: base64(ephemeral_pub (32) || iv (12) || ciphertext_with_tag)
  static Future<String> wrapSafeKey({
    required Uint8List safeKey,
    required Uint8List recipientPublicKey,
  }) async {
    final ephemeral = await _generateEphemeralPair();
    final shared = await _ecdh(
      ephiratalPriv: ephemeral.privateKey,
      peerPub: ephemeral.publicKey,
      peerPublicKey: recipientPublicKey,
    );
    final wrapKey = await _hkdf(shared, info: 'twinchat-safe-key-wrap-v1', length: 32);
    final wrapped = await AesGcm.encryptBytes(plaintext: safeKey, key: wrapKey);

    final ephemeralLen = ephemeral.publicKey.length;
    final ivLen = wrapped.iv.length;
    final ctLen = wrapped.ciphertextWithTag.length;
    final out = Uint8List(ephemeralLen + ivLen + ctLen);
    out.setRange(0, ephemeralLen, ephemeral.publicKey);
    out.setRange(ephemeralLen, ephemeralLen + ivLen, wrapped.iv);
    out.setRange(
      ephemeralLen + ivLen,
      ephemeralLen + ivLen + ctLen,
      wrapped.ciphertextWithTag,
    );
    return base64.encode(out);
  }

  /// Расшифровать safe-ключ своим private key.
  static Future<Uint8List> unwrapSafeKey({
    required String wrapped,
    required Uint8List myPrivateKey,
  }) async {
    final bytes = Uint8List.fromList(base64.decode(wrapped));
    final ephemeralPub = Uint8List.sublistView(bytes, 0, 32);
    final iv = Uint8List.sublistView(bytes, 32, 44);
    final ciphertextWithTag = Uint8List.sublistView(bytes, 44);
    final shared = await _ecdh(ephiratalPriv: myPrivateKey, peerPub: ephemeralPub, peerPublicKey: ephemeralPub);
    final wrapKey = await _hkdf(shared, info: 'twinchat-safe-key-wrap-v1', length: 32);
    return AesGcm.decryptToBytes(
      cipher: AesGcmCipher(iv: iv, ciphertextWithTag: ciphertextWithTag),
      key: wrapKey,
    );
  }

  /// Двойное шифрование: E2E-payload → safe layer.
  static Future<String> applySafeLayer({
    required String alreadyE2EEncryptedText,
    required Uint8List safeKey,
  }) {
    return AesGcm.encryptStringToBase64(
      plaintext: alreadyE2EEncryptedText,
      key: safeKey,
    );
  }

  /// Снять safe-слой.
  static Future<String> removeSafeLayer({
    required String safeEncryptedText,
    required Uint8List safeKey,
  }) {
    return AesGcm.decryptBase64ToString(
      input: safeEncryptedText,
      key: safeKey,
    );
  }

  // --- Helpers ---

  static Future<_XPair> _generateEphemeralPair() async {
    final algorithm = crypto.X25519();
    final kp = await algorithm.newKeyPair();
    final privBytes = await kp.extractPrivateKeyBytes();
    final pubKp = await kp.extractPublicKey();
    return _XPair(
      privateKey: Uint8List.fromList(privBytes),
      publicKey: Uint8List.fromList(pubKp.bytes),
    );
  }

  static Future<Uint8List> _ecdh({
    required Uint8List ephiratalPriv,
    required Uint8List peerPub,
    required Uint8List peerPublicKey,
  }) async {
    final algorithm = crypto.X25519();
    final myKp = await algorithm.newKeyPairFromSeed(ephiratalPriv);
    final shared = await algorithm.sharedSecretKey(
      keyPair: myKp,
      remotePublicKey: crypto.SimplePublicKey(
        Uint8List.fromList(peerPublicKey),
        type: crypto.KeyPairType.x25519,
      ),
    );
    return Uint8List.fromList(await shared.extractBytes());
  }

  static Future<Uint8List> _hkdf(
    Uint8List ikm, {
    required String info,
    required int length,
  }) async {
    final hkdf = crypto.Hkdf(
      hmac: crypto.Hmac.sha256(),
      outputLength: length,
    );
    final key = await hkdf.deriveKey(
      secretKey: crypto.SecretKey(ikm),
      nonce: Uint8List.fromList(utf8.encode(info)),
    );
    return Uint8List.fromList(await key.extractBytes());
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

class _XPair {
  _XPair({required this.privateKey, required this.publicKey});
  final Uint8List privateKey;
  final Uint8List publicKey;
}