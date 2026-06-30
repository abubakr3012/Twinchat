/// AES-256-GCM симметричное шифрование.
///
/// Формат на выходе:
///   base64( iv (12 байт) || ciphertext + tag (16 байт в конце) )
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

class AesGcmCipher {
  AesGcmCipher({required this.iv, required this.ciphertextWithTag});

  /// 12 байт.
  final Uint8List iv;

  /// ciphertext + 16-байтовый GCM tag в конце.
  final Uint8List ciphertextWithTag;

  /// Только ciphertext (без tag).
  Uint8List get ciphertext => Uint8List.sublistView(ciphertextWithTag, 0, ciphertextWithTag.length - 16);

  /// Только MAC tag (16 байт).
  Uint8List get tag => Uint8List.sublistView(ciphertextWithTag, ciphertextWithTag.length - 16);

  /// Сериализация для хранения.
  String toBase64() {
    final combined = Uint8List(iv.length + ciphertextWithTag.length)
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, iv.length + ciphertextWithTag.length, ciphertextWithTag);
    return base64.encode(combined);
  }

  factory AesGcmCipher.fromBase64(String input) {
    final bytes = base64.decode(input);
    final iv = Uint8List.sublistView(bytes, 0, 12);
    final ctWithTag = Uint8List.sublistView(bytes, 12);
    return AesGcmCipher(iv: iv, ciphertextWithTag: ctWithTag);
  }
}

class AesGcm {
  static final crypto.AesGcm _algorithm = crypto.AesGcm.with256bits();

  /// Сгенерировать 32-байтовый ключ.
  static Uint8List generateKey() {
    final rng = Random.secure();
    final bytes = Uint8List(32);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _randomIv() {
    final rng = Random.secure();
    final bytes = Uint8List(12);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return bytes;
  }

  /// Зашифровать UTF-8 строку.
  static Future<AesGcmCipher> encryptString({
    required String plaintext,
    required Uint8List key,
  }) {
    return encryptBytes(
      plaintext: Uint8List.fromList(utf8.encode(plaintext)),
      key: key,
    );
  }

  /// Зашифровать произвольные байты.
  static Future<AesGcmCipher> encryptBytes({
    required Uint8List plaintext,
    required Uint8List key,
  }) async {
    final secretKey = crypto.SecretKey(key);
    final iv = _randomIv();

    final box = await _algorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: iv,
    );

    // box.cipherText + box.mac.bytes
    final ctLen = box.cipherText.length;
    final macLen = box.mac.bytes.length;
    final combined = Uint8List(ctLen + macLen);
    combined.setRange(0, ctLen, box.cipherText);
    combined.setRange(ctLen, ctLen + macLen, box.mac.bytes);

    return AesGcmCipher(iv: iv, ciphertextWithTag: combined);
  }

  /// Расшифровать [AesGcmCipher] → строка.
  static Future<String> decryptToString({
    required AesGcmCipher cipher,
    required Uint8List key,
  }) async {
    final bytes = await decryptToBytes(cipher: cipher, key: key);
    return utf8.decode(bytes);
  }

  /// Расшифровать [AesGcmCipher] → байты.
  static Future<Uint8List> decryptToBytes({
    required AesGcmCipher cipher,
    required Uint8List key,
  }) async {
    final box = crypto.SecretBox(
      cipher.ciphertext,
      nonce: cipher.iv,
      mac: crypto.Mac(cipher.tag),
    );
    final clear = await _algorithm.decrypt(box, secretKey: crypto.SecretKey(key));
    return Uint8List.fromList(clear);
  }

  /// Helper: зашифровать строку → сразу base64.
  static Future<String> encryptStringToBase64({
    required String plaintext,
    required Uint8List key,
  }) async {
    final c = await encryptString(plaintext: plaintext, key: key);
    return c.toBase64();
  }

  /// Helper: расшифровать base64 → строка.
  static Future<String> decryptBase64ToString({
    required String input,
    required Uint8List key,
  }) async {
    final c = AesGcmCipher.fromBase64(input);
    return decryptToString(cipher: c, key: key);
  }
}