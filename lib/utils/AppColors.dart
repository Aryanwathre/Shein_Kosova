import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/hex_color.dart';

class AppColors {
  // -------------------------
  // Brand Colors
  // -------------------------

  static final Color primary = HexColor("#FF7A00");          // Orange
  static final Color primaryLight = HexColor("#FFA94D");     // Light Orange
  static final Color primaryDark = HexColor("#E66A00");      // Dark Orange

  // -------------------------
  // Background Colors
  // -------------------------

  static final Color background = HexColor("#FFFFFF");       // White
  static final Color backgroundLight = HexColor("#FFF3E5");  // Soft Cream
  static final Color backgroundGray = HexColor("#F4F4F4");   // Light Gray

  // -------------------------
  // Text Colors
  // -------------------------

  static final Color textDark = HexColor("#212121");         // Dark Charcoal
  static final Color textNormal = HexColor("#555555");       // Medium Gray
  static final Color textLight = HexColor("#9E9E9E");        // Light Gray Text
  static final Color textWhite = HexColor("#FFFFFF");        // Pure White Text

  // -------------------------
  // Border Colors
  // -------------------------

  static final Color border = HexColor("#DDDDDD");           // Light Border Gray
  static final Color borderLight = HexColor("#b5b5b5");      // Extra Light Border
  static final Color borderDark = HexColor("#AAAAAA");       // Medium Border Gray

  // -------------------------
  // Icon Colors
  // -------------------------

  static final Color iconPrimary = primary;                  // Orange (Primary)
  static final Color iconDark = HexColor("#212121");         // Dark Charcoal
  static final Color iconLight = HexColor("#757575");        // Gray
  static final Color iconWhite = HexColor("#FFFFFF");        // White

  // -------------------------
  // Button Colors
  // -------------------------

  static final Color buttonPrimary = primary;                // Orange
  static final Color buttonSecondary = primaryLight;         // Light Orange

  // -------------------------
  // Status Colors
  // -------------------------

  static final Color error = HexColor("#FF4D4D");            // Red
  static final Color success = HexColor("#4CAF50");          // Green
  static final Color warning = HexColor("#FFC107");          // Amber

  // -------------------------
  // Effects / Shadows / Overlay
  // -------------------------

  static final Color shadow = HexColor("#33FF7A00");         // Orange (20% opacity)
  static final Color overlay = HexColor("#11FF7A00");        // Orange (7% opacity)

  // -------------------------
  // Card Background
  // -------------------------

  static final Color cardBackground = HexColor("#FFFFFF");   // White

  // -------------------------
  // General Colors
  // -------------------------

  static const Color black = Colors.black;                   // Pure Black
  static const Color white = Colors.white;                   // Pure White
  static const Color transparent = Colors.transparent;       // Transparent

  static final Color grey50 = HexColor("#FAFAFA");           // Very Light Grey
  static final Color grey100 = HexColor("#F5F5F5");          // Light Grey
  static final Color grey200 = HexColor("#EEEEEE");          // Soft Grey
  static final Color grey300 = HexColor("#E0E0E0");          // Border Grey
  static final Color grey400 = HexColor("#BDBDBD");          // Medium Light Grey
  static final Color grey500 = HexColor("#9E9E9E");          // Standard Light Grey
  static final Color grey600 = HexColor("#757575");          // Grey
  static final Color grey700 = HexColor("#616161");          // Darker Grey
  static final Color grey800 = HexColor("#424242");          // Dark Grey
  static final Color grey900 = HexColor("#212121");          // Almost Black
}
