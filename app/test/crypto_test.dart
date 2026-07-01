import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twinchat/core/crypto/aes_gcm.dart';
import 'package:twinchat/core/crypto/message_crypto.dart';
import 'package:twinchat/core/crypto/x25519_keys.dart';

void main() {
  group('AesGcm', () {
    test('encrypt/decrypt roundtrip для строки', () async {
      final key = AesGcm.generateKey();
      const plaintext = 'Привет, TwinChat! 👋';
      final cipher = await AesGcm.encryptString(plaintext: plaintext, key: key);

      expect(cipher.iv.length, 12);
      expect(cipher.ciphertextWithTag.length, greaterThan(16));

      final decoded = await AesGcm.decryptToString(cipher: cipher, key: key);
      expect(decoded, plaintext);
    });

    test('encrypt/decrypt roundtrip для байтов', () async {
      final key = AesGcm.generateKey();
      final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final cipher = await AesGcm.encryptBytes(plaintext: bytes, key: key);

      final decoded = await AesGcm.decryptToBytes(cipher: cipher, key: key);
      expect(decoded, bytes);
    });

    test('base64 roundtrip сохраняет payload', () {
      final iv = Uint8List.fromList(List.generate(12, (i) => i + 1));
      final ctWithTag = Uint8List.fromList(List.generate(64, (i) => i));
      final cipher = AesGcmCipher(iv: iv, ciphertextWithTag: ctWithTag);
      final b64 = cipher.toBase64();
      final restored = AesGcmCipher.fromBase64(b64);
      expect(restored.iv, cipher.iv);
      expect(restored.ciphertextWithTag, cipher.ciphertextWithTag);
    });

    test('неверный ключ даёт ошибку при расшифровке', () async {
      final key1 = AesGcm.generateKey();
      final key2 = AesGcm.generateKey();
      final cipher = await AesGcm.encryptString(plaintext: 'secret', key: key1);
      await expectLater(
        AesGcm.decryptToString(cipher: cipher, key: key2),
        throwsA(anything),
      );
    });
  });

  group('X25519', () {
    test('генерация ключей даёт 32-байтовые пары', () async {
      final pair = await X25519KeyGenerator.generate();
      expect(pair.privateSeed.length, 32);
      expect(pair.publicKey.length, 32);
    });

    test('base64 roundtrip пары', () async {
      final pair = await X25519KeyGenerator.generate();
      final restored = await X25519KeyPair.fromPrivateSeedBase64(
        pair.privateKeyToBase64(),
      );
      expect(restored.privateSeed, pair.privateSeed);
      expect(restored.publicKey, pair.publicKey);
    });

    test('ECDH даёт одинаковый секрет у обеих сторон', () async {
      final alice = await X25519KeyGenerator.generate();
      final bob = await X25519KeyGenerator.generate();

      final aliceSecret = await alice.sharedSecretWith(bob);
      final bobSecret = await bob.sharedSecretWith(alice);

      expect(aliceSecret.length, 32);
      expect(aliceSecret, bobSecret);
    });

    test('ECDH с разными парами даёт разные секреты', () async {
      final alice = await X25519KeyGenerator.generate();
      final bob = await X25519KeyGenerator.generate();
      final eve = await X25519KeyGenerator.generate();

      final aliceBob = await alice.sharedSecretWith(bob);
      final aliceEve = await alice.sharedSecretWith(eve);

      expect(aliceBob, isNot(equals(aliceEve)));
    });
  });

  group('MessageCrypto', () {
    test('encrypt для Bob расшифровывается Bob-ом', () async {
      final alice = await X25519KeyGenerator.generate();
      final bob = await X25519KeyGenerator.generate();

      final ct = await MessageCrypto.encryptForRecipient(
        myPrivateKey: alice.privateSeed,
        recipientPublicKey: bob.publicKey,
        conversationId: 'chat-1',
        plaintext: 'Привет от Alice',
      );

      final pt = await MessageCrypto.decryptFromSender(
        myPrivateKey: bob.privateSeed,
        senderPublicKey: alice.publicKey,
        conversationId: 'chat-1',
        encryptedTextB64: ct,
      );

      expect(pt, 'Привет от Alice');
    });

    test('fingerprint стабилен для одного и того же ключа', () async {
      final alice = await X25519KeyGenerator.generate();
      final bob = await X25519KeyGenerator.generate();

      final shared = await alice.sharedSecretWith(bob);
      final sessionKey = await MessageCrypto.deriveSessionKey(
        sharedSecret: shared,
        conversationId: 'chat-1',
      );

      final fp1 = await MessageCrypto.fingerprint(sessionKey);
      final fp2 = await MessageCrypto.fingerprint(sessionKey);

      expect(fp1, fp2);
      expect(fp1.length, 8);
    });

    test('разные conversation_id дают разные session keys', () async {
      final alice = await X25519KeyGenerator.generate();
      final bob = await X25519KeyGenerator.generate();
      final shared = await alice.sharedSecretWith(bob);

      final key1 = await MessageCrypto.deriveSessionKey(
        sharedSecret: shared,
        conversationId: 'chat-1',
      );
      final key2 = await MessageCrypto.deriveSessionKey(
        sharedSecret: shared,
        conversationId: 'chat-2',
      );

      expect(key1, isNot(equals(key2)));
    });
  });

  group('Safe Mode (через AesGcm)', () {
    test('safe-layer поверх E2E roundtrip', () async {
      final safeKey = AesGcm.generateKey();

      // Имитация E2E payload
      final e2ePayload = base64.encode(List.generate(64, (i) => i));

      // Шифруем safe-слоем
      final safeWrapped = await AesGcm.encryptStringToBase64(
        plaintext: e2ePayload,
        key: safeKey,
      );

      // Снимаем safe-слой
      final recovered = await AesGcm.decryptBase64ToString(
        input: safeWrapped,
        key: safeKey,
      );

      expect(recovered, e2ePayload);
    });
  });
}