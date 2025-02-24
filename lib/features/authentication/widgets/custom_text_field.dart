import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  const CustomTextField({
    Key? key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.black.withOpacity(0.8),
      ),
      validator: validator,
      keyboardType: keyboardType,
    );
  }
}

