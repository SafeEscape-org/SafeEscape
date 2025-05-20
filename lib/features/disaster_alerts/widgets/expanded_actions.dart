import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class ExpandedActions extends StatelessWidget {
  final VoidCallback onNavigationStart;

  const ExpandedActions({
    super.key,
    required this.onNavigationStart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: onNavigationStart, // This should set isExpanded to true
        style: ElevatedButton.styleFrom(
          backgroundColor: EvacuationColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions),
            const SizedBox(width: 8),
            Text(
              'Start Navigation',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}