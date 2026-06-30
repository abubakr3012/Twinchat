import 'package:flutter/material.dart';

/// "Пузырь" сообщения в чате.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.time,
    this.status,
    this.encrypted = false,
    this.tail = true,
  });

  final String text;
  final bool isMine;
  final String? time;
  final String? status; // для MessageStatusIcon
  final bool encrypted;
  final bool tail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine ? scheme.primary : scheme.surfaceContainerHigh;
    final fg = isMine ? scheme.onPrimary : scheme.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: tail ? radius : BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (encrypted) ...[
                  Icon(Icons.lock, size: 12, color: fg.withOpacity(0.7)),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(color: fg, fontSize: 15),
                  ),
                ),
              ],
            ),
            if (time != null || status != null) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        color: fg.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  if (status != null && isMine) ...[
                    const SizedBox(width: 4),
                    // status icon адаптируется под цвет пузыря
                    _StatusOnBubble(status: status!, mineColor: fg),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusOnBubble extends StatelessWidget {
  const _StatusOnBubble({required this.status, required this.mineColor});
  final String status;
  final Color mineColor;

  @override
  Widget build(BuildContext context) {
    final c = mineColor.withOpacity(0.7);
    switch (status) {
      case 'seen':
        return Icon(Icons.done_all, size: 14, color: Theme.of(context).colorScheme.primary);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: c);
      case 'sent':
        return Icon(Icons.done, size: 14, color: c);
      case 'pending':
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.4, color: c),
        );
      case 'failed':
        return Icon(Icons.error_outline, size: 14, color: Theme.of(context).colorScheme.error);
      default:
        return const SizedBox.shrink();
    }
  }
}