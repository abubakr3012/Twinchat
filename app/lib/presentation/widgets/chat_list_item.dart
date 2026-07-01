import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'avatar_widget.dart';

/// Элемент списка чатов в стиле WhatsApp.
class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    this.onTap,
    this.onLongPress,
  });

  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final String? time;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Avatar with online indicator
                UserAvatar(
                  url: avatarUrl,
                  name: name,
                  size: 56,
                  showOnline: true,
                  isOnline: isOnline,
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (time != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              time!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: unreadCount > 0
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Last message and unread badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage ?? 'Нет сообщений',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99
                                    ? '99+'
                                    : unreadCount.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
