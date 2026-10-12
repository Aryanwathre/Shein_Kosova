import 'package:flutter/material.dart';
import 'package:shein_kosova/utils/AppColors.dart';

Widget inputField({
  required TextEditingController controller,
  required String label,
  TextInputType keyboardType = TextInputType.text,
  TextInputAction textInputAction = TextInputAction.next,
  bool? obscureText = false,
  int maxLines = 1,
  void Function(String)? onChanged,
  String? Function(String?)? validator,
  Color? backgroundColor,
  Color? borderColor,
  IconButton? suffixIcon,
}) {
  backgroundColor ??= AppColors.background;
  borderColor ??= AppColors.borderDark;
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    textInputAction: textInputAction,
    obscureText: obscureText!,
    decoration: InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: AppColors.grey400),
      filled: true,
      fillColor: backgroundColor,
      suffixIcon: suffixIcon,
      // Optional styling
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
    onChanged: onChanged,
    validator: validator ??
            (value) =>
        value == null || value.isEmpty ? "Please enter $label" : null,
  );
}
