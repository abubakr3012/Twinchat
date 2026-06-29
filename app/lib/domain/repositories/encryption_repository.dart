import '../entities/encryption.dart';

abstract class EncryptionRepository {
  Future<SafeModeStatus> status();
  Future<SafeModeStatus> enable({
    required String encryptedKey,
    required String keyFingerprint,
  });
  Future<void> disable();

  Future<List<SafeModeKeyShare>> shares();
  Future<SafeModeKeyShare> share({
    required int sharedWithUserId,
    required String method,
  });
  Future<void> revoke(int shareId);

  Future<SafeModeUIState> uiState();
  Future<SafeModeUIState> updateUiState(SafeModeUIState state);
}
