import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/theam.dart';

// Shows the discounted (sale) price with the regular price struck through when
// there is a real discount; otherwise just the regular price.
Widget discountedPriceRow(double price, double salePrice, {double fontSize = 18}) {
  final hasDiscount = salePrice > 0 && salePrice < price;
  if (!hasDiscount) return styledPrice(price, fontSize: fontSize);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: styledPrice(salePrice, fontSize: fontSize)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          '${price.toStringAsFixed(2)}€',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize - 5,
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ),
    ],
  );
}

Widget styledPrice(double price, {Color? color,double fontSize = 18 }) {
  final priceStr = price.toStringAsFixed(2);
  final parts = priceStr.split('.');
  color ??= AppTheme.theme.primaryColor;

  return Text.rich(
    TextSpan(
      text: parts[0],
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
