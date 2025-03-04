import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
class HeaderComponent extends StatelessWidget {
  final String userName;
  final VoidCallback? onSettingsTap;

  const HeaderComponent({
    Key? key,
    this.userName = 'AliHyder',
    this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
            child: Text(
              userName[0].toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF1976D2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // In the GestureDetector widget
          GestureDetector(
            onTap: onSettingsTap, // Use the callback directly
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3).withOpacity(0.1),
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 24,
                color: const Color(0xFF1976D2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}