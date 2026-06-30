/// Curve25519 (X25519) пара ключей для ECDH.
///
/// Формат хранения:
/// - private seed: 32 байта (X25519 private key)
/// - public key: 32 байта
/// - обе сериализуются в base64 для передачи по сети
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' as crypto;

/// Пара Curve25519 ключей для ECDH. Непотокобезопасна: кэширует internal KeyPair.
class X25519KeyPair {
  X25519KeyPair._({
    required this.privateSeed,
    required this.publicKey,
    required crypto.SimpleKeyPair keyPair,
  }) : _keyPair = keyPair;

  /// 32 байта private seed.
  final Uint8List privateSeed;

  /// 32 байта public key.
  final Uint8List publicKey;

  final crypto.SimpleKeyPair _keyPair;

  String privateKeyToBase64() => base64.encode(privateSeed);
  String publicKeyToBase64() => base64.encode(publicKey);

  /// Восстановить пару из private seed.
  static Future<X25519KeyPair> fromPrivateSeedBase64(String b64) async {
    return fromPrivateSeed(Uint8List.fromList(base64.decode(b64)));
  }

  static Future<X25519KeyPair> fromPrivateSeed(Uint8List seed) async {
    final algorithm = crypto.X25519();
    final kp = await algorithm.newKeyPairFromSeed(seed);
    final pub = await kp.extractPublicKey();
    return X25519KeyPair._(
      privateSeed: Uint8List.fromList(seed),
      publicKey: Uint8List.fromList(pub.bytes),
      keyPair: kp,
    );
  }

  /// Создать "remote" пару только из public key (для ECDH с другой стороной).
  static Future<X25519KeyPair> fromPublicKeyBase64(String b64) async {
    final algorithm = crypto.X25519();
    // Создаём через dummy seed чтобы получить KeyPairType, но без реального private key.
    // Используем только publicKey, передаём в sharedSecretKey как remotePublicKey.
    final seed = Uint8List(32);
    final kp = await algorithm.newKeyPairFromSeed(seed);
    final pub = Uint8List.fromList(base64.decode(b64));
    return X25519KeyPair._(
      privateSeed: Uint8List(32),
      publicKey: pub,
      keyPair: kp,
    );
  }

  /// ECDH → общий секрет (32 байта).
  Future<Uint8List> sharedSecretWith(X25519KeyPair remote) async {
    final algorithm = crypto.X25519();
    final sharedSecretKey = await algorithm.sharedSecretKey(
      keyPair: _keyPair,
      remotePublicKey: crypto.SimplePublicKey(
        Uint8List.fromList(remote.publicKey),
        type: crypto.KeyPairType.x25519,
      ),
    );
    return Uint8List.fromList(await sharedSecretKey.extractBytes());
  }
}

class X25519KeyGenerator {
  /// Сгенерировать новую пару ключей.
  static Future<X25519KeyPair> generate() async {
    final algorithm = crypto.X25519();
    final kp = await algorithm.newKeyPair();
    final seedBytes = await kp.extractPrivateKeyBytes();
    final pub = await kp.extractPublicKey();
    return X25519KeyPair._(
      privateSeed: Uint8List.fromList(seedBytes),
      publicKey: Uint8List.fromList(pub.bytes),
      keyPair: kp,
    );
  }
}
