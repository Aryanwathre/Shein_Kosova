import 'package:flutter/material.dart';

class HexColor extends Color {
  static int _getColorFromHex(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF$hex";
    }

    return int.parse(hex, radix: 16);
  }

  HexColor(final String hex) : super(_getColorFromHex(hex));
}
