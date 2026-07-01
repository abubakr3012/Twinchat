import 'package:flutter/material.dart';

/// Тема приложения TwinChat — Material Design 3, уникальный фирменный стиль.
/// Бирюзовый/зелёный оттенок — ассоциация с общением и коммуникацией.
class AppTheme {
  AppTheme._();

  // ─── Цветовая палитра TwinChat ─────────────────────────────────────
  static const Color _primaryLight = Color(0xFF00BFA6);
  static const Color _primaryDark = Color(0xFF00E5CC);
  static const Color _secondaryLight = Color(0xFF004D40);
  static const Color _secondaryDark = Color(0xFF80CBC4);
  static const Color _surfaceLight = Color(0xFFFAFFFE);
  static const Color _surfaceDark = Color(0xFF1A1C1E);
  static const Color _errorLight = Color(0xFFBA1A1A);
  static const Color _errorDark = Color(0xFFFFB4AB);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _primaryLight,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFB2F5DB),
      onPrimaryContainer: const Color(0xFF002114),
      secondary: _secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFA7EEE5),
      onSecondaryContainer: const Color(0xFF002020),
      tertiary: const Color(0xFF4A6572),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFD1E9F8),
      onTertiaryContainer: const Color(0xFF051F2A),
      error: _errorLight,
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: _surfaceLight,
      onSurface: const Color(0xFF191C1B),
      onSurfaceVariant: const Color(0xFF3F4946),
      outline: const Color(0xFF6F7975),
      outlineVariant: const Color(0xFFBFC9C5),
      shadow: Colors.black26,
      inverseSurface: const Color(0xFF2E312F),
      onInverseSurface: const Color(0xFFEFF1EF),
      surfaceTint: _primaryLight,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryDark,
      onPrimary: const Color(0xFF00382E),
      primaryContainer: const Color(0xFF005044),
      onPrimaryContainer: const Color(0xFF72F8D8),
      secondary: _secondaryDark,
      onSecondary: const Color(0xFF1D3533),
      secondaryContainer: const Color(0xFF354C49),
      onSecondaryContainer: const Color(0xFFA7EEE5),
      tertiary: const Color(0xFFB2CDDC),
      onTertiary: const Color(0xFF1C333E),
      tertiaryContainer: const Color(0xFF334A57),
      onTertiaryContainer: const Color(0xFFD1E9F8),
      error: _errorDark,
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFB4AB),
      surface: _surfaceDark,
      onSurface: const Color(0xFFE1E3E1),
      onSurfaceVariant: const Color(0xFFBFC9C5),
      outline: const Color(0xFF89938F),
      outlineVariant: const Color(0xFF3F4946),
      shadow: Colors.black54,
      inverseSurface: const Color(0xFFE1E3E1),
      onInverseSurface: const Color(0xFF191C1B),
      surfaceTint: _primaryDark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final textTheme = _textTheme(scheme);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: scheme.surface,

      // ─── Text Theme ──────────────────────────────────────────────
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // ─── Navigation Bar ──────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? scheme.surface : scheme.surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          );
        }),
      ),

      // ─── Input Decoration ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withOpacity(0.3)
            : scheme.surfaceContainerHighest.withOpacity(0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.6)),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      // ─── Buttons ─────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 1,
          shadowColor: scheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          elevation: 1,
          shadowColor: scheme.primary.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),

      // ─── Card Theme ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ─── Dialog Theme ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),

      // ─── Bottom Sheet ────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),

      // ─── Snackbar ────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // ─── Chip Theme ──────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: scheme.secondaryContainer.withOpacity(0.5),
        selectedColor: scheme.primaryContainer,
        labelStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outline.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),

      // ─── Divider ─────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.4),
        thickness: 0.5,
        space: 0,
      ),

      // ─── List Tile ───────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 14,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
