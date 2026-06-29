import 'package:equatable/equatable.dart';

/// Доменная сущность реакции (эмодзи) на сообщение.
class Reaction extends Equatable {
  const Reaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.username,
    required this.emoji,
  });

  final int id;
  final int messageId;
  final int userId;
  final String username;
  final String emoji;

  @override
  List<Object?> get props => [id, messageId, userId, username, emoji];
}
