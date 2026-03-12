import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlWidget extends StatelessWidget {
  /// The HTML string to display
  final String htmlString;

  /// Background color of the widget
  final Color? backgroundColor;

  /// Text color for the HTML content
  final Color? textColor;

  /// Font size for the HTML content
  final double? fontSize;

  /// Padding around the HTML content
  final EdgeInsets padding;

  /// Width constraint for the widget
  final double? width;

  /// Height constraint for the widget
  final double? height;

  /// Whether to scroll if content overflows
  final bool scrollable;

  const HtmlWidget({
    Key? key,
    required this.htmlString,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding = const EdgeInsets.all(8.0),
    this.width,
    this.height,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.transparent,
      padding: padding,
      child: scrollable
          ? SingleChildScrollView(
              child: _buildHtmlContent(),
            )
          : _buildHtmlContent(),
    );
  }

  Widget _buildHtmlContent() {
    return Html(
      data: htmlString,
      style: {
        'body': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize(fontSize ?? 14.0),
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
        'p': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize(fontSize ?? 14.0),
          margin: Margins.symmetric(vertical: 8.0),
        ),
        'h1': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize((fontSize ?? 14.0) * 2.0),
          fontWeight: FontWeight.bold,
          margin: Margins.symmetric(vertical: 12.0),
        ),
        'h2': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize((fontSize ?? 14.0) * 1.8),
          fontWeight: FontWeight.bold,
          margin: Margins.symmetric(vertical: 10.0),
        ),
        'h3': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize((fontSize ?? 14.0) * 1.6),
          fontWeight: FontWeight.bold,
          margin: Margins.symmetric(vertical: 8.0),
        ),
        'b': Style(
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black,
        ),
        'strong': Style(
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black,
        ),
        'i': Style(
          fontStyle: FontStyle.italic,
          color: textColor ?? Colors.black,
        ),
        'em': Style(
          fontStyle: FontStyle.italic,
          color: textColor ?? Colors.black,
        ),
        'u': Style(
          textDecoration: TextDecoration.underline,
          color: textColor ?? Colors.black,
        ),
        'a': Style(
          color: const Color(0xFF1976D2),
          textDecoration: TextDecoration.underline,
        ),
        'li': Style(
          color: textColor ?? Colors.black,
          fontSize: FontSize(fontSize ?? 14.0),
          margin: Margins.symmetric(vertical: 4.0),
        ),
        'ul': Style(
          color: textColor ?? Colors.black,
          margin: Margins.symmetric(vertical: 8.0),
        ),
        'ol': Style(
          color: textColor ?? Colors.black,
          margin: Margins.symmetric(vertical: 8.0),
        ),
      },
    );
  }
}
