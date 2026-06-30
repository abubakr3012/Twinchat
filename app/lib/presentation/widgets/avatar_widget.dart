import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Аватар пользователя / чата с фолбэком на инициалы.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.url,
    required this.name,
    this.size = 48,
    this.onTap,
  });

  final String? url;
  final String name;
  final double size;
  final VoidCallback? onTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Color _seedColor(BuildContext context) {
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    final colors = Theme.of(context).colorScheme.primary;
    final palette = <Color>[
      colors,
      colors.withOpacity(0.7),
      colors.withOpacity(0.5),
      colors.withOpacity(0.85),
    ];
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _seedColor(context),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    final avatar = url == null || url!.isEmpty
        ? placeholder
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
          );

    if (onTap == null) return avatar;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: avatar,
    );
  }
}