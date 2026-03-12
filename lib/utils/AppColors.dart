import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shein_kosova/utils/hex_color.dart';

class AppColors {
  static String? _dynamicPrimaryHex;

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _dynamicPrimaryHex = prefs.getString('config_color');
  }

  // -------------------------
  // Brand Colors
  // -------------------------

  static Color get primary => _dynamicPrimaryHex != null ? HexColor(_dynamicPrimaryHex!) : const Color(0xFFFF7A00);          // Orange
  static Color get primaryLight => _dynamicPrimaryHex != null ? HexColor(_dynamicPrimaryHex!).withValues(alpha: 0.7) : const Color(0xFFFFA94D);     // Light Orange

  // To darken a color properly without exceeding 1.0 opacity:
  static Color get primaryDark {
    if (_dynamicPrimaryHex != null) {
      final color = HexColor(_dynamicPrimaryHex!);
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    }
    return const Color(0xFFE66A00); // Dark Orange
  }

  // -------------------------
  // Background Colors
  // -------------------------

  static const Color background = Color(0xFFFFFFFF);       // White
  static const Color backgroundLight = Color(0xFFFFF3E5);  // Soft Cream
  static const Color backgroundGray = Color(0xFFF4F4F4);   // Light Gray

  // -------------------------
  // Text Colors
  // -------------------------

  static const Color textDark = Color(0xFF212121);         // Dark Charcoal
  static const Color textNormal = Color(0xFF555555);       // Medium Gray
  static const Color textLight = Color(0xFF9E9E9E);        // Light Gray Text
  static const Color textWhite = Color(0xFFFFFFFF);        // Pure White Text

  // -------------------------
  // Border Colors
  // -------------------------

  static const Color border = Color(0xFFDDDDDD);           // Light Border Gray
  static const Color borderLight = Color(0xFFB5B5B5);      // Extra Light Border
  static const Color borderDark = Color(0xFFAAAAAA);       // Medium Border Gray

  // -------------------------
  // Icon Colors
  // -------------------------

  static Color get iconPrimary => primary;                  // Orange (Primary)
  static const Color iconDark = Color(0xFF212121);         // Dark Charcoal
  static const Color iconLight = Color(0xFF757575);        // Gray
  static const Color iconWhite = Color(0xFFFFFFFF);        // White

  // -------------------------
  // Button Colors
  // -------------------------

  static Color get buttonPrimary => primary;                // Orange
  static Color get buttonSecondary => primaryLight;         // Light Orange

  // -------------------------
  // Status Colors
  // -------------------------

  static const Color error = Color(0xFFFF4D4D);            // Red
  static const Color success = Color(0xFF4CAF50);          // Green
  static const Color warning = Color(0xFFFFC107);          // Amber

  // -------------------------
  // Effects / Shadows / Overlay
  // -------------------------

  static Color get shadow => primary.withValues(alpha: 0.2);         // Orange (20% opacity)
  static Color get overlay => primary.withValues(alpha: 0.07);        // Orange (7% opacity)

  // -------------------------
  // Card Background
  // -------------------------

  static const Color cardBackground = Color(0xFFFFFFFF);   // White

  // -------------------------
  // General Colors
  // -------------------------

  static const Color black = Colors.black;                   // Pure Black
  static const Color white = Colors.white;                   // Pure White
  static const Color transparent = Colors.transparent;       // Transparent

  static const Color grey50 = Color(0xFFFAFAFA);           // Very Light Grey
  static const Color grey100 = Color(0xFFF5F5F5);          // Light Grey
  static const Color grey200 = Color(0xFFEEEEEE);          // Soft Grey
  static const Color grey300 = Color(0xFFE0E0E0);          // Border Grey
  static const Color grey400 = Color(0xFFBDBDBD);          // Medium Light Grey
  static const Color grey500 = Color(0xFF9E9E9E);          // Standard Light Grey
  static const Color grey600 = Color(0xFF757575);          // Grey
  static const Color grey700 = Color(0xFF616161);          // Darker Grey
  static const Color grey800 = Color(0xFF424242);          // Dark Grey
  static const Color grey900 = Color(0xFF212121);          // Almost Black

  static const Color grey = grey500;
}
