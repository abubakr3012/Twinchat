import 'package:equatable/equatable.dart';

/// Тип звонка.
enum CallType { voice, video, unknown }

CallType callTypeFromString(String? value) {
  switch (value) {
    case 'voice':
      return CallType.voice;
    case 'video':
      return CallType.video;
    default:
      return CallType.unknown;
  }
}

/// Статус звонка (значения из бэкенда).
enum CallStatus { ringing, active, ended, rejected, missed, unknown }

CallStatus callStatusFromString(String? value) {
  switch (value) {
    case 'ringing':
      return CallStatus.ringing;
    case 'active':
      return CallStatus.active;
    case 'ended':
      return CallStatus.ended;
    case 'rejected':
      return CallStatus.rejected;
    case 'missed':
      return CallStatus.missed;
    default:
      return CallStatus.unknown;
  }
}

/// Доменная сущность звонка.
class Call extends Equatable {
  const Call({
    required this.id,
    required this.chatId,
    required this.initiatorId,
    required this.initiatorUsername,
    required this.callType,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.createdAt,
  });

  final int id;
  final int chatId;
  final int initiatorId;
  final String initiatorUsername;
  final CallType callType;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        chatId,
        initiatorId,
        initiatorUsername,
        callType,
        status,
        startedAt,
        endedAt,
        durationSeconds,
        createdAt,
      ];
}
