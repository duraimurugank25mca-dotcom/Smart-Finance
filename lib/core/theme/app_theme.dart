import 'package:flutter/material.dart';

class AppTheme {
  // Brand Purple Colors (From Reference UI)
  static const Color primaryPurple = Color(0xFF6D28D9);       // Main vibrant violet / purple
  static const Color primaryPurpleDark = Color(0xFF5B21B6);   // Darker purple for hover/press
  static const Color primaryPurpleDeep = Color(0xFF4C1D95);   // Deep royal violet
  static const Color purpleGlow = Color(0xFF7C3AED);         // Glowing accent purple
  static const Color purpleLightBg = Color(0xFFF5F3FF);      // Soft lavender background
  static const Color purplePillBg = Color(0xFFF3EEFF);       // Pill & active container background
  static const Color purpleBorder = Color(0xFFDDD6FE);       // Soft purple outline border

  // Semantic Status Colors (From Reference UI)
  static const Color incomeGreen = Color(0xFF10B981);         // Mint / emerald green for Income
  static const Color incomeGreenDark = Color(0xFF059669);
  static const Color incomeGreenBg = Color(0xFFECFDF5);      // Soft green background

  static const Color expenseRed = Color(0xFFF43F5E);          // Coral / rose red for Expenses
  static const Color expenseRedDark = Color(0xFFE11D48);
  static const Color expenseRedBg = Color(0xFFFFF1F2);        // Soft red background
  static const Color expenseRedBorder = Color(0xFFFECDD3);

  static const Color balanceBlue = Color(0xFF6D28D9);         // Available balance purple
  static const Color advancesGold = Color(0xFFF59E0B);        // Amber / gold for advances & EMI
  static const Color advancesGoldBg = Color(0xFFFEF3C7);
  static const Color clientIndigo = Color(0xFF8B5CF6);        // Soft violet for pending bills

  // Backgrounds & Surface (Clean White & Lavender Tint)
  static const Color appBackground = Color(0xFFF8F9FD);      // Light lavender-tinted crisp off-white
  static const Color cardBackground = Color(0xFFFFFFFF);     // Pure crisp white card
  static const Color cardBorder = Color(0xFFEEF0F8);         // Ultra-fine light border
  static const Color dividerColor = Color(0xFFF1F3F9);

  // Typography Palette
  static const Color textDarkNavy = Color(0xFF0F172A);       // Dark headings & large values
  static const Color textSecondary = Color(0xFF64748B);      // Medium slate gray for labels & subtext
  static const Color textMuted = Color(0xFF94A3B8);          // Light muted gray for captions
  static const Color textPurple = Color(0xFF6D28D9);         // Highlighted purple text

  // Dark Palette
  static const Color darkBg = Color(0xFF0D0B18);
  static const Color darkCard = Color(0xFF19162B);
  static const Color darkCardElevated = Color(0xFF26213F);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFA19EBB);

  // Light Theme (Default, matching reference screenshots)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: appBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      onPrimary: Colors.white,
      secondary: purpleGlow,
      surface: cardBackground,
      onSurface: textDarkNavy,
      error: expenseRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cardBackground,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textDarkNavy,
      ),
      iconTheme: IconThemeData(color: textDarkNavy),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardBorder, width: 1.2),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryPurple, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        side: const BorderSide(color: purpleBorder, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardBackground,
      elevation: 3,
      indicatorColor: purplePillBg,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: textSecondary, fontWeight: FontWeight.normal, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryPurple, size: 24);
        }
        return const IconThemeData(color: textSecondary, size: 22);
      }),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      onPrimary: Colors.white,
      secondary: purpleGlow,
      surface: darkCard,
      onSurface: darkTextPrimary,
      error: expenseRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      iconTheme: IconThemeData(color: darkTextPrimary),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2548), width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3B3560)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF3B3560)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
  );
}
