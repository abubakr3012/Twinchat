import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Аватар пользователя / чата с градиентом и инициалами.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.url,
    required this.name,
    this.size = 56,
    this.onTap,
    this.showOnline = false,
    this.isOnline = false,
  });

  final String? url;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showOnline;
  final bool isOnline;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  List<Color> _gradientColors(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final scheme = Theme.of(context).colorScheme;
    final palettes = [
      [scheme.primary, scheme.primary.withOpacity(0.7)],
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFFEC4899), const Color(0xFFF472B6)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
    ];
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradientColors(context);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.35),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final avatar = url == null || url!.isEmpty
        ? placeholder
        : ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.35),
            child: CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
          );

    final result = showOnline
        ? Stack(
            children: [
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return result;
    return GestureDetector(
      onTap: onTap,
      child: result,
    );
  }
}
