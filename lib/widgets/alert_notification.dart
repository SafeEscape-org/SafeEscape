import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AlertNotification extends StatelessWidget {
  final String title;
  final String message;
  final String alertType;
  final VoidCallback? onTap;

  const AlertNotification({
    Key? key,
    required this.title,
    required this.message,
    required this.alertType,
    this.onTap,
  }) : super(key: key);

  String _getAnimationAsset() {
    switch (alertType.toLowerCase()) {
      case 'flood':
        return 'assets/animations/flood_alert.json';
      case 'fire':
        return 'assets/animations/fire_alert.json';
      case 'earthquake':
        return 'assets/animations/earthquake_alert.json';
      case 'storm':
        return 'assets/animations/storm_alert.json';
      default:
        return 'assets/animations/general_alert.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Lottie.asset(
                      _getAnimationAsset(),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}