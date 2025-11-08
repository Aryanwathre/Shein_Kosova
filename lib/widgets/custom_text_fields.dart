import 'package:flutter/material.dart';

Widget inputField({
  required TextEditingController controller,
  required String label,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  void Function(String)? onChanged,
  String? Function(String?)? validator,

}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: label, // Changed from hint: Text(label) to hintText
    ),
    onChanged: onChanged, // <-- pass it here
    validator: (value) =>
    value == null || value.isEmpty ? "Please enter $label" : null,
  );
}
