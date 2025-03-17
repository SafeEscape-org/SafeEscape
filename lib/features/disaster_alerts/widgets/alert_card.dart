import 'package:disaster_management/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AlertCard extends StatefulWidget {
  final String title;
  final String description;
  final String severity;
  final String time;
  final String alertType; // Changed from IconData to String
  final Color color;

  const AlertCard({
    super.key,
    required this.title,
    required this.description,
    required this.severity,
    required this.time,
    required this.alertType,
    required this.color,
  });

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;

  String _getLottieAsset() {
    switch (widget.alertType.toLowerCase()) {
      case 'flood':
        return 'assets/animations/flood_alert.json';
      case 'earthquake':
        return 'assets/animations/earthquake_alert.json';
      case 'fire':
        return 'assets/animations/fire_alert.json';
      case 'storm':
        return 'assets/animations/storm_alert.json';
      default:
        return 'assets/animations/general_alert.json';
    }
  }

  IconData _getAlertIcon() {
    switch (widget.alertType.toLowerCase()) {
      case 'flood':
        return FontAwesomeIcons.water;
      case 'earthquake':
        return FontAwesomeIcons.houseChimneyCrack;
      case 'fire':
        return FontAwesomeIcons.fire;
      case 'storm':
        return FontAwesomeIcons.cloudBolt;
      default:
        return FontAwesomeIcons.triangleExclamation;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  Widget _buildAnimatedIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.2),
            blurRadius: 10 * _pulseAnimation.value,
            spreadRadius: 2 * _pulseAnimation.value,
          ),
        ],
      ),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Lottie.asset(
          _getLottieAsset(),
          fit: BoxFit.contain,
          animate: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Card(
            elevation: 1 + (_pulseAnimation.value - 1) * 5,
            shadowColor: AppColors.primaryColor.withOpacity(0.05 + (_pulseAnimation.value - 1) * 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: AppColors.primaryColor.withOpacity(0.1 + (_pulseAnimation.value - 1) * 0.2),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: GoogleFonts.inter(
                              color: AppColors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            )),
                        const SizedBox(height: 6),
                        Text(widget.description,
                            style: GoogleFonts.inter(
                              color: AppColors.textColor.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.4,
                            )),
                        const SizedBox(height: 12),
                        _buildAnimatedStatusRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStatusRow() {
    return Row(
      children: [
        _buildPulsingChip(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.severity,
                style: GoogleFonts.inter(
                  color: AppColors.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildPulsingChip(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.time,
                style: GoogleFonts.inter(
                  color: AppColors.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPulsingChip({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08 + (_pulseAnimation.value - 1) * 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}