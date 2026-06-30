import 'package:flutter/material.dart';

/// Иконки статуса сообщения: отправлено / доставлено / прочитано.
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon({
    super.key,
    required this.status,
    this.color,
  });

  /// 'sent' | 'delivered' | 'seen' | 'pending' | 'failed'
  final String status;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.outline;
    switch (status) {
      case 'seen':
        return Icon(Icons.done_all, size: 16, color: Theme.of(context).colorScheme.primary);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: c);
      case 'sent':
        return Icon(Icons.done, size: 16, color: c);
      case 'pending':
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c),
        );
      case 'failed':
        return Icon(Icons.error_outline, size: 16, color: Theme.of(context).colorScheme.error);
      default:
        return const SizedBox.shrink();
    }
  }
}