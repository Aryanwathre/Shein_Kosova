import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/theam.dart';

Widget styledPrice(double price, {Color? color,double fontSize = 18 }) {
  final priceStr = price.toStringAsFixed(2);
  final parts = priceStr.split('.');
  color ??= AppTheme.theme.primaryColor;

  return Text.rich(
    TextSpan(
      text: "${parts[0]}",
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      children: [
        TextSpan(
          text: ".${parts[1]}€",
          style: TextStyle(
            fontSize: fontSize - 6,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );
}
