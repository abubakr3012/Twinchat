import '../../domain/entities/encryption.dart';
import '../../domain/repositories/encryption_repository.dart';
import '../datasources/encryption_remote.dart';
import '../mappers/encryption_mapper.dart';
import '../models/encryption_dto.dart';

class EncryptionRepositoryImpl implements EncryptionRepository {
  EncryptionRepositoryImpl(this._remote);
  final EncryptionRemote _remote;

  @override
  Future<SafeModeStatus> status() async =>
      (await _remote.status()).toDomain();

  @override
  Future<SafeModeStatus> enable({
    required String encryptedKey,
    required String keyFingerprint,
  }) async {
    final dto = await _remote.enable(
      encryptedKey: encryptedKey,
      keyFingerprint: keyFingerprint,
    );
    return dto.toDomain();
  }

  @override
  Future<void> disable() => _remote.disable();

  @override
  Future<List<SafeModeKeyShare>> shares() async {
    final dtos = await _remote.shares();
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<SafeModeKeyShare> share({
    required int sharedWithUserId,
    required String method,
  }) async {
    final dto = await _remote.share(
      sharedWithUserId: sharedWithUserId,
      method: method,
    );
    return dto.toDomain();
  }

  @override
  Future<void> revoke(int shareId) => _remote.revoke(shareId);

  @override
  Future<SafeModeUIState> uiState() async =>
      (await _remote.uiState()).toDomain();

  @override
  Future<SafeModeUIState> updateUiState(SafeModeUIState state) async {
    final dto = await _remote.updateUiState(
      SafeModeUIDto(
        keyEntered: state.keyEntered,
        autoLockMinutes: state.autoLockMinutes,
      ),
    );
    return dto.toDomain();
  }
}