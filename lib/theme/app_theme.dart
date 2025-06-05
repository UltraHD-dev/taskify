import 'package:flutter/material.dart';

class AppTheme {
  static const double borderRadius = 12.0;
  static const double padding = 16.0;

  static final lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6B4EFF),
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF4E97FF),
    tertiary: const Color(0xFFFF4E8C),
    surface: const Color(0xFFFAFAFC),
  );

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6B4EFF),
    brightness: Brightness.dark,
  ).copyWith(
    secondary: const Color(0xFF4E97FF),
    tertiary: const Color(0xFFFF4E8C),
    surface: const Color(0xFF1A1B1E),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    brightness: Brightness.light,
    
    scaffoldBackgroundColor: lightColorScheme.surface,
    
    appBarTheme: AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: lightColorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: lightColorScheme.onSurface,
      ),
    ),
    
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding / 2,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(lightColorScheme.primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: padding * 1.5,
            vertical: padding,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withAlpha(25),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(lightColorScheme.primary),
        overlayColor: WidgetStatePropertyAll(
          lightColorScheme.primary.withAlpha(13),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: padding,
            vertical: padding / 2,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightColorScheme.surfaceContainerHighest.withAlpha(77),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(
          color: lightColorScheme.primary,
          width: 1.5,
        ),
      ),
      prefixIconColor: lightColorScheme.onSurfaceVariant,
      suffixIconColor: lightColorScheme.onSurfaceVariant,
    ),
    
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        color: lightColorScheme.primary,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: lightColorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: lightColorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: lightColorScheme.onSurfaceVariant,
      ),
      useIndicator: true,
      indicatorColor: lightColorScheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: lightColorScheme.primaryContainer.withAlpha(77),
      selectedColor: lightColorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: lightColorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius / 2),
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: padding / 2,
        vertical: padding / 4,
      ),
    ),
  );

  // Dark theme имеет аналогичные изменения
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    brightness: Brightness.dark,
    // ... аналогичные изменения для темной темы
  );
}