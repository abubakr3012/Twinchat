import 'package:equatable/equatable.dart';

/// Доменная сущность контакта.
class Contact extends Equatable {
  const Contact({
    required this.id,
    required this.contactId,
    required this.username,
    this.avatarUrl,
    this.nickname,
    this.isBlocked = false,
    this.addedAt,
  });

  final int id;
  final int contactId;
  final String username;
  final String? avatarUrl;
  final String? nickname;
  final bool isBlocked;
  final DateTime? addedAt;

  /// Имя для UI: никнейм или username.
  String get displayName =>
      (nickname != null && nickname!.isNotEmpty) ? nickname! : username;

  @override
  List<Object?> get props =>
      [id, contactId, username, avatarUrl, nickname, isBlocked, addedAt];
}
