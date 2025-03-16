import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGradientCircle(
          top: -100,
          right: -50,
          size: 250,
          colors: [
            AppColors.primaryColor.withOpacity(0.15),
            AppColors.accentColor.withOpacity(0.1)
          ],
        ),
        _buildGradientCircle(
          bottom: -120,
          left: -80,
          size: 280,
          colors: [
            AppColors.accentColor.withOpacity(0.15),
            AppColors.primaryColor.withOpacity(0.1)
          ],
          isReversed: true,
        ),
        _buildCenterCircle(context),
      ],
    );
  }

  Widget _buildGradientCircle({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required List<Color> colors,
    bool isReversed = false,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: isReversed ? Alignment.bottomRight : Alignment.topLeft,
            end: isReversed ? Alignment.topLeft : Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildCenterCircle(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: MediaQuery.of(context).size.width * 0.5,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              AppColors.accentColor.withOpacity(0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}