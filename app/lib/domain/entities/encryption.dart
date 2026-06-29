import 'package:equatable/equatable.dart';

/// Состояние Safe Mode для текущего пользователя.
class SafeModeStatus extends Equatable {
  const SafeModeStatus({required this.isActive, this.fingerprint});

  final bool isActive;
  final String? fingerprint; // первые 8 символов ключа

  @override
  List<Object?> get props => [isActive, fingerprint];
}

/// Запись о передаче ключа.
class SafeModeKeyShare extends Equatable {
  const SafeModeKeyShare({
    required this.id,
    required this.userId,
    required this.username,
    required this.sharedWithId,
    required this.sharedWithUsername,
    required this.method,
    this.sharedAt,
    this.isRevoked = false,
  });

  final int id;
  final int userId;
  final String username;
  final int sharedWithId;
  final String sharedWithUsername;
  final String method; // 'qr' | 'copy' | 'link' | 'nfc'
  final DateTime? sharedAt;
  final bool isRevoked;

  @override
  List<Object?> get props => [
        id,
        userId,
        username,
        sharedWithId,
        sharedWithUsername,
        method,
        sharedAt,
        isRevoked,
      ];
}

/// Клиентское состояние UI для Safe Mode.
class SafeModeUIState extends Equatable {
  const SafeModeUIState({
    required this.keyEntered,
    required this.autoLockMinutes,
  });

  final bool keyEntered;
  final int autoLockMinutes;

  SafeModeUIState copyWith({bool? keyEntered, int? autoLockMinutes}) =>
      SafeModeUIState(
        keyEntered: keyEntered ?? this.keyEntered,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      );

  @override
  List<Object?> get props => [keyEntered, autoLockMinutes];
}
