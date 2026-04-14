import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // iOS System Colors (dark mode values)
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF30D158);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemRed = Color(0xFFFF453A);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemPurple = Color(0xFFBF5AF2);
  static const Color systemTeal = Color(0xFF64D2FF);

  // iOS Grays (dark mode)
  static const Color label = Color(0xFFFFFFFF); // primary text
  static const Color secondaryLabel = Color(0x99FFFFFF); // secondary text
  static const Color tertiaryLabel = Color(0x4DFFFFFF); // placeholder
  static const Color quaternaryLabel = Color(0x2EFFFFFF); // disabled
  static const Color systemBackground = Color(0xFF000000); // screen bg
  static const Color secondaryBackground = Color(0xFF1C1C1E); // grouped bg
  static const Color tertiaryBackground = Color(0xFF2C2C2E); // elevated cards
  static const Color separator = Color(0x33545458); // dividers
  static const Color opaqueSeparator = Color(0xFF38383A); // solid dividers

  // Legacy color palette (for backwards compatibility)
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color secondaryColor = Color(0xFF5856D6);
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);
  static const Color warningColor = Color(0xFFFF9500);
  
  // Text colors
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);

  // Glassmorphism
  static const Color glassBackground = Color(0x80FFFFFF);
  static const Color glassBorder = Color(0x1A000000);

  // iOS Human Interface Guidelines type scale
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
  );
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
  );
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.35,
  );
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.43,
  );
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.43,
  );
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
  );
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.23,
  );
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
  );
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.06,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
    ),
    platform: TargetPlatform.iOS, // Force iOS scroll physics
    scaffoldBackgroundColor: backgroundColor,
    textTheme: const TextTheme(
      displayLarge: largeTitle,
      displayMedium: title1,
      displaySmall: title2,
      headlineMedium: title3,
      headlineSmall: headline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: subheadline,
      labelSmall: footnote,
      titleSmall: caption1,
      titleMedium: caption2,
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  static final textTheme = const TextTheme(
      displayLarge: largeTitle,
      displayMedium: title1,
      displaySmall: title2,
      headlineMedium: title3,
      headlineSmall: headline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: subheadline,
      labelSmall: footnote,
      titleSmall: caption1,
      titleMedium: caption2,
    ),
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: secondaryColor,
      background: const Color(0xFF000000),
      surface: const Color(0xFF1C1C1E),
      error: errorColor,
    ),
    platform: TargetPlatform.iOS, // Force iOS scroll physics
    scaffoldBackgroundColor: const Color(0xFF000000),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle.light,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1C1C1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
