import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AppColors.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.background,
      onPrimary: AppColors.textWhite,
      onSecondary: AppColors.textWhite,
      onSurface: AppColors.textDark,
      error: AppColors.error,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.iconDark),
      titleTextStyle: GoogleFonts.outfit(
        color: AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    textTheme: TextTheme(
      headlineLarge: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.outfit(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
      bodyLarge: GoogleFonts.outfit(color: AppColors.textDark),
      bodyMedium: GoogleFonts.outfit(color: AppColors.textNormal),
      labelLarge: GoogleFonts.outfit(color: AppColors.textWhite, fontWeight: FontWeight.bold),
    ),

    iconTheme: IconThemeData(
      color: AppColors.iconDark,
      size: 24,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        side: const BorderSide(color: AppColors.black, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.black,
      elevation: 4,
      shape: const CircleBorder(),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textDark,
      unselectedLabelColor: AppColors.textLight,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.primary,
      selectedLabelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),

    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      shadowColor: AppColors.shadow,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(0),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textDark,
      contentTextStyle: GoogleFonts.outfit(color: AppColors.textWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.grey200,
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      disabledColor: AppColors.grey200,
      selectedColor: AppColors.black,
      secondarySelectedColor: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
      secondaryLabelStyle: GoogleFonts.outfit(color: AppColors.textWhite, fontSize: 12),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
    ),
  );
}
