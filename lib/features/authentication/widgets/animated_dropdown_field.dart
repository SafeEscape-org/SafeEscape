import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class AnimatedDropdownField extends StatelessWidget {
  final String value;
  final String label;
  final IconData prefixIcon;
  final List<String> items;
  final Function(String?) onChanged;
  final AnimationController animation;
  final double delay;

  const AnimatedDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    required this.animation,
    this.delay = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double progress = Curves.easeOutCubic.transform(
          ((animation.value - delay).clamp(0, 1 - delay)) / (1 - delay),
        );

        return Transform.translate(
          offset: Offset(0, 40 * (1 - progress)),
          child: Opacity(
            opacity: progress,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildDropdown(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          color: Colors.grey[600],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primaryColor.withOpacity(0.7),
        ),
      ),
      style: GoogleFonts.montserrat(
        fontSize: 16,
        color: AppColors.textColor,
      ),
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.montserrat(),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}