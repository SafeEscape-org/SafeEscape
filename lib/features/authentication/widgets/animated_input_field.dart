import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

// Add the enabled parameter to the constructor
class AnimatedInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final double delay;
  final Animation<double> animation;
  final bool isPassword;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final bool enabled;
  final String? Function(String?)? validator; // Add custom validator parameter

  const AnimatedInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.delay,
    required this.animation,
    this.isPassword = false,
    this.keyboardType,
    this.maxLines = 1,
    this.obscureText = false,
    this.onTogglePassword,
    this.enabled = true,
    this.validator, // Add validator to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = _calculateProgress();
        return _buildAnimatedContainer(progress, child!);
      },
      child: _buildInputField(),
    );
  }

  double _calculateProgress() {
    return Curves.easeOutCubic.transform(
      ((animation.value - delay).clamp(0, 1 - delay)) / (1 - delay),
    );
  }

  Widget _buildAnimatedContainer(double progress, Widget child) {
    return Transform.translate(
      offset: Offset(0, 40 * (1 - progress)),
      child: Opacity(
        opacity: progress,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: _inputDecoration,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled, // Add this line
        style: _textStyle,
        decoration: _fieldDecoration,
        validator: _validator,
      ),
    );
  }

  BoxDecoration get _inputDecoration => BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  TextStyle get _textStyle => GoogleFonts.montserrat(
        fontSize: 16,
        color: AppColors.textColor,
      );

  InputDecoration get _fieldDecoration => InputDecoration(
        labelText: label,
        labelStyle: _labelStyle,
        floatingLabelStyle: _floatingLabelStyle,
        prefixIcon: Icon(icon, color: AppColors.primaryColor.withOpacity(0.7), size: 22),
        suffixIcon: _buildSuffixIcon(),
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildBorder(isActive: true),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );

  TextStyle get _labelStyle => GoogleFonts.montserrat(
        color: Colors.grey[600],
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _floatingLabelStyle => GoogleFonts.montserrat(
        color: AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  Widget? _buildSuffixIcon() {
    if (!isPassword) return null;
    return IconButton(
      icon: Icon(
        obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
        color: Colors.grey[500],
        size: 22,
      ),
      onPressed: onTogglePassword,
    );
  }

  OutlineInputBorder _buildBorder({bool isActive = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isActive ? AppColors.primaryColor : Colors.grey[200]!,
          width: isActive ? 1.5 : 1,
        ),
      );

  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}