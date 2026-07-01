import 'package:flutter/material.dart';

/// "Пузырь" сообщения в чате с современным дизайном.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.time,
    this.status,
    this.encrypted = false,
    this.tail = true,
    this.child,
  });

  final String text;
  final bool isMine;
  final String? time;
  final String? status;
  final bool encrypted;
  final bool tail;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final fg = isMine ? scheme.onPrimary : scheme.onSurface;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMine ? 18 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 18),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: tail ? radius : BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (child != null) ...[
              child!,
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (encrypted) ...[
                  Icon(Icons.lock_rounded,
                      size: 12, color: fg.withOpacity(0.6)),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (time != null || status != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        color: fg.withOpacity(0.55),
                        fontSize: 11,
                      ),
                    ),
                  if (status != null && isMine) ...[
                    const SizedBox(width: 4),
                    _StatusIcon(status: status!, color: fg),
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

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = color.withOpacity(0.7);
    switch (status) {
      case 'seen':
        return Icon(Icons.done_all_rounded,
            size: 16, color: const Color(0xFF34B7F1));
      case 'delivered':
        return Icon(Icons.done_all_rounded, size: 16, color: c);
      case 'sent':
        return Icon(Icons.done_rounded, size: 16, color: c);
      case 'pending':
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: c,
          ),
        );
      case 'failed':
        return Icon(Icons.error_outline_rounded,
            size: 16, color: Theme.of(context).colorScheme.error);
      default:
        return const SizedBox.shrink();
    }
  }
}
