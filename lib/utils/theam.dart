import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryOrange = Color(0xFFFF7A00); // vibrant orange
  static const Color lightOrange = Color(0xFFFFA94D); // softer shade
  static const Color darkOrange = Color(0xFFE66A00);
  static const Color backgroundWhite = Colors.white;
  static const Color textBlack = Colors.black87;
  static const Color textGray = Colors.black54;

  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryOrange,
    scaffoldBackgroundColor: backgroundWhite,
    colorScheme: ColorScheme.light(
      primary: primaryOrange,
      secondary: lightOrange,
      surface: backgroundWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textBlack,
    ),

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundWhite,
      foregroundColor: textBlack,
      elevation: 0,
      iconTheme: IconThemeData(color: textBlack),
      titleTextStyle: TextStyle(
        color: textBlack,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Text
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textBlack,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textBlack,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: textBlack),
      bodyMedium: TextStyle(color: textGray),
      labelLarge: TextStyle(color: Colors.white),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryOrange,
        side: const BorderSide(color: primaryOrange, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryOrange,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.orange.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryOrange),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryOrange, width: 2),
      ),
      hintStyle: const TextStyle(color: textGray),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryOrange,
      foregroundColor: Colors.white,
    ),

    // TabBar
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryOrange,
      unselectedLabelColor: textGray,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryOrange, width: 2),
      ),
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundWhite,
      selectedItemColor: primaryOrange,
      unselectedItemColor: textGray,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      shadowColor: Colors.orange.shade50,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // SnackBar
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primaryOrange,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Colors.white,
    ),

    // Switch, Checkbox, Radio
    switchTheme: SwitchThemeData(
      trackColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
              ? primaryOrange.withOpacity(0.6)
              : Colors.grey.shade300),
      thumbColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
              ? primaryOrange
              : Colors.grey.shade400),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
              ? primaryOrange
              : Colors.grey.shade200),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith(
              (states) => states.contains(MaterialState.selected)
              ? primaryOrange
              : Colors.grey),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),
  );
}
